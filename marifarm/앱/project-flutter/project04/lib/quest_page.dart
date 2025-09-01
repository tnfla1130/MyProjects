import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/quest_service.dart';
import '../models/quest_models.dart';
import '../models/auth_models.dart';

/// UI 전용 퀘스트 상태
enum QuestState { none, pending, done }

class QuestPage extends StatefulWidget {
  const QuestPage({super.key});

  @override
  State<QuestPage> createState() => _QuestPageState();
}

class _QuestPageState extends State<QuestPage> {
  late final int _userIdx;

  // 서버에서 내려온 퀘스트 마스터 / 내 상태
  List<Quest> _quests = [];
  List<UserQuest> _my = [];
  final Map<int, QuestState> _states = {}; // questId -> state

  bool _loading = true;

  static const Color green = Color(0xFF8FBC8F);

  @override
  void initState() {
    super.initState();
    final u = AuthService.instance.user;
    _userIdx = int.tryParse(u?.memberIdx ?? '0') ?? 0;

    _refreshAll();
  }

  /// HUD 동기화: AuthService만 갱신 (로컬 상태 없음)
  Future<void> _refreshHud() async {
    await AuthService.instance.fetchMe(silent: true);
  }

  Future<void> _refreshAll() async {
    setState(() => _loading = true);
    try {
      // 1) 데이터 병렬/순차 로드
      final quests = await QuestService.instance.getQuests();
      final my = await QuestService.instance.getMyUserQuests();
      await AuthService.instance.fetchMe(silent: true); // 서버 기준 최신 동기화

      if (!mounted) return;

      // 2) 상태 계산
      final todayKey = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
      final byId = {for (final u in my) u.questId: u};

      final states = <int, QuestState>{};
      for (final q in quests) {
        final uq = byId[q.questId];
        final isDaily = (q.questType == QuestType.dailyAttendance || q.questType == QuestType.dailyPhoto);

        QuestState st;
        if (uq == null) {
          st = QuestState.pending;
        } else if (uq.status == 'y') {
          st = isDaily
              ? (uq.windowKey == todayKey ? QuestState.done : QuestState.pending)
              : QuestState.done;
        } else {
          st = QuestState.pending;
        }
        states[q.questId] = st;
      }

      // 3) UI 반영 (HUD는 AuthService 구독이므로 건드릴 필요 없음)
      setState(() {
        _quests = quests;
        _my = my;
        _states..clear()..addAll(states);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('퀘스트/상태 로딩 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _typeLabel(QuestType t) {
    switch (t) {
      case QuestType.dailyAttendance:
        return '출석 체크';
      case QuestType.dailyPhoto:
        return '사진 찍기';
      default:
        return '퀘스트';
    }
  }

  Future<void> _claimReward(Quest quest) async {
    final st = _states[quest.questId] ?? QuestState.pending;
    if (st != QuestState.pending) return; // 이미 완료 or 미등록 상태면 막기

    try {
      final res = await QuestService.instance.completeQuest(
        QuestCompleteRequest(userIdx: _userIdx, questId: quest.questId),
        expected: quest,
      );
      if (!mounted) return;

      if (res != null && res.success) {
        // 1) 응답에 최신 지갑이 오면 바로 패치
        if (res.newGamePoint != null || res.newExp != null || res.newLevel != null) {
          AuthService.instance.applyMePatch(
            gamePoint: res.newGamePoint,
            gameExp:   res.newExp,
            gameLevel: res.newLevel,
          );
        } else {
          // 2) 아니면 서버 기준으로 /me 재조회
          await AuthService.instance.fetchMe(silent: true);
        }

        // 퀘스트 카드 상태만 로컬로 완료 처리
        setState(() {
          _states[quest.questId] = QuestState.done;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('보상 지급! +${res.goldGained} 코인, +${res.expGained} XP'),
          ),
        );

        // 내 상태 다시 가져와 정합성 보정(선택)
        try {
          final my = await QuestService.instance.getMyUserQuests();
          if (!mounted) return;
          setState(() => _my = my);
        } catch (_) {}
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('퀘스트 완료 실패')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('퀘스트 완료 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀘스트'),
        backgroundColor: green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ✅ HUD: AuthService 구독
                ValueListenableBuilder<AuthUser?>(
                  valueListenable: AuthService.instance.currentUser,
                  builder: (_, u, __) {
                    final coins = u?.gamePoint ?? 0;
                    final xp = u?.gameExp ?? 0;
                    return _WalletCard(coins: coins, xp: xp);
                  },
                ),
                const SizedBox(height: 16),

                if (_quests.isEmpty)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(18.0),
                      child: Text('진행 가능한 퀘스트가 없습니다.'),
                    ),
                  )
                else
                  ..._quests.map((q) {
                    final st = _states[q.questId] ?? QuestState.pending;
                    final canClaim = st == QuestState.pending;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuestCard(
                        title: q.questName.isNotEmpty ? q.questName : _typeLabel(q.questType),
                        subtitle: q.description,
                        rewardGold: q.rewardGold,
                        rewardExp: q.rewardExp,
                        state: st,
                        onPressedClaim: canClaim ? () => _claimReward(q) : null,
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

/* =================== [구성요소 UI 위젯들] =================== */

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.coins, required this.xp});
  final int coins;
  final int xp;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _StatBox(
              leading: Image.asset(
                'assets/images/coin.png', // 경로 통일
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.savings_outlined),
              ),
              label: '코인',
              value: coins.toString(),
            ),
            const SizedBox(width: 12),
            _StatBox(
              leading: Image.asset(
                'assets/images/exp.png', // 경로 통일
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(Icons.bolt_outlined),
              ),
              label: '경험치',
              value: xp.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            leading,
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.onPressedClaim,
    required this.rewardGold,
    required this.rewardExp,
  });

  final String title;
  final String subtitle;
  final QuestState state;
  final VoidCallback? onPressedClaim;
  final int rewardGold;
  final int rewardExp;

  @override
  Widget build(BuildContext context) {
    final stateMeta = _stateMeta(state);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: stateMeta.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(stateMeta.icon, size: 28, color: stateMeta.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('보상: ', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      Image.asset(
                        'assets/images/coin.png',
                        width: 14,
                        height: 14,
                        errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 14),
                      ),
                      const SizedBox(width: 4),
                      Text('+$rewardGold', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Image.asset(
                        'assets/images/exp.png',
                        width: 14,
                        height: 14,
                        errorBuilder: (_, __, ___) => const Icon(Icons.star, size: 14),
                      ),
                      const SizedBox(width: 4),
                      Text('+$rewardExp', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: onPressedClaim,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: Colors.grey.shade200,
                disabledForegroundColor: Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('보상 받기'),
            ),
          ],
        ),
      ),
    );
  }

  _QuestStateMeta _stateMeta(QuestState s) {
    switch (s) {
      case QuestState.pending:
        return _QuestStateMeta(
          label: '보상 대기',
          icon: Icons.hourglass_top_rounded,
          color: const Color(0xFF6B8E23),
        );
      case QuestState.done:
        return _QuestStateMeta(
          label: '완료됨',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF2E7D32),
        );
      case QuestState.none:
        return _QuestStateMeta(
          label: '미등록',
          icon: Icons.block_outlined,
          color: Colors.grey,
        );
    }
  }
}

class _QuestStateMeta {
  final String label;
  final IconData icon;
  final Color color;
  _QuestStateMeta({
    required this.label,
    required this.icon,
    required this.color,
  });
}
