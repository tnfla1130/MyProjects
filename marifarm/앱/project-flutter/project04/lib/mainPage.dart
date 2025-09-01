// lib/mainPage.dart
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:project_04/calendar_page.dart';
import 'package:project_04/design_page.dart';
import 'package:project_04/loginPage.dart';
import 'package:project_04/quest_page.dart';
import 'package:project_04/shopPage.dart';

import 'services/auth_service.dart';
import 'models/auth_models.dart';

// 꾸미기 상태
import 'services/decor_service.dart';
import 'models/decor_models.dart';
import 'services/shop_service.dart'; // imageUrl 변환

// 마스코트(캐릭터)
import 'services/character_service.dart';
import 'models/character_models.dart';

/// ===========================================
/// 디버그 설정
/// ===========================================
class DebugConfig {
  bool showOverlay;
  bool drawBorders;
  bool forceUrlHost;
  String forcedBase;
  bool useHardcodedLayers;
  double scale;
  bool verboseLogs;

  DebugConfig({
    this.showOverlay = false,
    this.drawBorders = false,
    this.forceUrlHost = false,
    this.forcedBase = 'http://10.0.2.2:8080',
    this.useHardcodedLayers = false,
    this.scale = 1.0,
    this.verboseLogs = false,
  });
}

DebugConfig _gDebug = DebugConfig();

/// ===========================================
/// 유틸: URL → 레이어 매핑
/// ===========================================
String? _roleFromUrl(String? u) {
  final s = (u ?? '').toLowerCase();
  if (s.contains('roof') || s.contains('bg') || s.contains('background')) return '배경';
  if (s.contains('left') || s.contains('l_') || s.contains('side_l')) return '왼쪽';
  if (s.contains('right') || s.contains('r_') || s.contains('side_r')) return '오른쪽';
  if (s.contains('below') || s.contains('floor') || s.contains('ground')) return '바닥';
  if (s.contains('dolphin') || s.contains('center') || s.contains('mid') || s.contains('middle')) return '중앙';
  if (s.contains('front') || s.contains('fore') || s.contains('fg')) return '전경';
  return null;
}

String _fixAbsoluteUrl(String raw) {
  String url;
  try {
    url = ShopService.imageUrl(raw);
  } catch (_) {
    url = raw;
  }

  final u = Uri.tryParse(url);
  if (u != null && u.hasScheme) {
    if (_gDebug.forceUrlHost) {
      final path = '${u.path}${u.hasQuery ? '?${u.query}' : ''}';
      final forced = Uri.parse(_gDebug.forcedBase);
      final fixed = forced.replace(path: path.startsWith('/') ? path : '/$path');
      return fixed.toString();
    }
    return url;
  }

  final base = _gDebug.forcedBase;
  final fixed = Uri.parse(base).replace(path: url.startsWith('/') ? url : '/$url');
  return fixed.toString();
}

Map<String, String> _urlsFromTheme(List<EquippedItem> items) {
  final out = <String, String>{};
  for (final e in items) {
    final r = _roleFromUrl(e.url);
    if (r == null) continue;
    final raw = (e.url ?? '').trim();
    if (raw.isEmpty) continue;
    out[r] = _fixAbsoluteUrl(raw);
  }
  return out;
}

class MainPage extends StatelessWidget {
  final AuthUser? authUser;

  const MainPage({super.key, this.authUser});

  @override
  Widget build(BuildContext context) {
    if (authUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "로그인 정보를 불러올 수 없습니다.",
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }
    return HomePage(authUser: authUser!);
  }
}

class HomePage extends StatefulWidget {
  final AuthUser authUser;
  const HomePage({super.key, required this.authUser});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<String> messages = [
    "오늘도 와줘서 고마워~ 나 많이 보고 싶었어!",
    "물 조금만 주면 힘이 날 것 같아",
    "햇살 너무 좋아~ 너도 기분 좋지?",
    "오늘은 기분이 꿀꿀해… 토닥토닥해줄래?",
    "나 사실… 춤출 줄 알아! (하지만 뿌리가 붙어 있어서 못 보여줘…)",
    "밤에 몰래 성장 중이야… 그래서 키가 조금 커졌을지도?",
    "나랑 얘기하느라 물 주는 거 깜빡한 거 아니지?",
    "너랑 함께 있으니까 내가 더 잘 자라는 것 같아!",
    "오늘도 멋지다~ 네가 있어서 행복해",
    "조금 힘들어 보여… 괜찮아, 난 네 편이야",
    "하루하루 조금씩 나아가는 거야. 나처럼!",
    "오늘도 나랑 같이 힘내자~ 화이팅!",
    "햇살이 너무 포근해. 너도 꼭 따뜻한 하루 보내!",
    "오늘 하루 수고 많았어. 토닥토닥~",
    "내가 작은 등불이 되어줄게. 편히 쉬어",
    "힘들면 잠시 나랑 수다 떨고 가!",
    "작은 나도 이렇게 열심히 크는 걸. 너도 충분히 잘하고 있어",
  ];
  String currentMessage = "대화창을 클릭해보세요!";

  Map<String, EquippedItem> _equipped = {};
  bool _equippedLoading = true;

  /// 여름테마
  List<EquippedItem> _summer = [];

  int _userIdx = 0;

  /// 마스코트
  Mascot? _mascot;
  bool _mascotLoading = true;

  /// 🔥 레벨 변화에 따라 UI에서 강제 적용할 스테이지(진화)
  int? _overrideStage;

  String get _displayName {
    final mName = (_mascot?.name ?? '').trim();
    if (mName.isNotEmpty) return mName;
    final nick = (widget.authUser.nickname ?? '').trim();
    if (nick.isNotEmpty) return nick;
    return widget.authUser.userId ?? 'Guest';
  }

  @override
  void initState() {
    super.initState();
    _userIdx = int.tryParse(widget.authUser.memberIdx ?? '') ?? 0;

    // 앱 시작 시 AuthService에 유저가 없으면 시드
    if (AuthService.instance.user == null) {
      AuthService.instance.setUser(AuthUser(
        memberIdx: widget.authUser.memberIdx,
        userId: widget.authUser.userId,
        nickname: widget.authUser.nickname,
        gamePoint: widget.authUser.gamePoint,
        gameExp: widget.authUser.gameExp,
        gameLevel: widget.authUser.gameLevel,
      ));
    }

    // 🔥 초기 진화 상태는 현재 레벨로 계산
    _overrideStage = _stageFromLevel(widget.authUser.gameLevel);

    // 🔥 레벨/코인/EXP 변화 감지(퀘스트/상점 후 /me 반영 시 콜백)
    AuthService.instance.currentUser.addListener(_onUserChanged);

    _loadEquipped();
    _initMascot();
  }

  @override
  void dispose() {
    AuthService.instance.currentUser.removeListener(_onUserChanged);
    super.dispose();
  }

  /// ✅ 레벨 → 스테이지 규칙 (원하면 구간 수정)
  int _stageFromLevel(int level) {
    if (level >= 30) return 4; // 만개
    if (level >= 15) return 3; // 봉오리
    if (level >= 5)  return 2; // 새싹
    return 1;                  // 씨앗
  }

  /// ✅ 유저 정보가 갱신될 때(코인/EXP/레벨) 진화 반영
  void _onUserChanged() {
    final u = AuthService.instance.currentUser.value;
    if (u == null) return;
    final nextStage = _stageFromLevel(u.gameLevel);
    if (_overrideStage != nextStage) {
      setState(() => _overrideStage = nextStage);
      // (선택) 진화 토스트:
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('마스코트가 스테이지 $nextStage 로 진화!')),
      // );
    }
    // HUD는 AnimatedBuilder가 알아서 그림
  }

  Map<String, EquippedItem> _flattenLatest(Map<String, List<EquippedItem>> buckets) {
    final out = <String, EquippedItem>{};
    buckets.forEach((slot, list) {
      if (list.isNotEmpty) out[slot] = list.last;
    });
    return out;
  }

  Future<void> _loadEquipped() async {
    setState(() => _equippedLoading = true);
    try {
      final buckets = await DecorService.getEquipped();
      if (!mounted) return;

      final latest = _flattenLatest(buckets);
      setState(() {
        _equipped = latest;
        _summer = buckets['여름테마'] ?? buckets['summer'] ?? buckets['SUMMER'] ?? [];
      });
    } catch (_) {
      // 침묵 실패
    } finally {
      if (mounted) setState(() => _equippedLoading = false);
    }
  }

  /// 마스코트 초기화
  Future<void> _initMascot() async {
    setState(() => _mascotLoading = true);
    try {
      Mascot cur = await CharacterService.instance.getMyMascot();
      if (!mounted) return;

      if (cur.name.trim().isEmpty) {
        final name = await _askMascotName(initial: '내마스코트');
        if (!mounted) return;

        if (name != null && name.trim().isNotEmpty) {
          cur = await CharacterService.instance.registerNameOnce(name.trim());
        }
      }

      if (!mounted) return;
      setState(() => _mascot = cur);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('마스코트 초기화 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _mascotLoading = false);
    }
  }

  /// 이름 입력
  Future<String?> _askMascotName({String initial = ''}) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('마스코트 이름을 지어주세요'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '이름 입력'),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(context, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('건너뛰기'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  /// 마스코트 아바타 (🔥 진화 스테이지 오버라이드 적용)
  Widget _buildMascotAvatar({
  double width = 150,
  double height = 150,
}) {
  final stage = _overrideStage ?? (_mascot?.stage ?? 1);
  final asset = _assetForStage(stage);
  final name = _mascot?.name;

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          asset,
          fit: BoxFit.contain,
          // ✅ 에셋 로드 실패 시 아이콘으로 안전 폴백
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.pets, size: 80, color: Colors.grey),
          ),
        ),
      ),
      if (name != null && name.isNotEmpty)
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
    ],
  );
}

  /// 단계→에셋 매핑
  String _assetForStage(int stage) {
    switch (stage) {
      case 1:
        return 'assets/images/mascot_seed.png';
      case 2:
        return 'assets/images/mascot_sprout.png';
      case 3:
        return 'assets/images/mascot_bud.png';
      case 4:
      default:
        return 'assets/images/mascot_bloom.png';
    }
  }

  Future<void> _afterReturnFromShop(dynamic result) async {
    // 최신 내 지갑 상태 재조회 후 HUD 자동 반영
    await AuthService.instance.refreshMe();
    await _loadEquipped();
  }

  Future<void> _afterReturnFromDesign(dynamic _) async {
    await _loadEquipped();
    await AuthService.instance.refreshMe();
  }

  void showRandomMessage() {
    final random = Random();
    setState(() {
      currentMessage = messages[random.nextInt(messages.length)];
    });
  }

  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = _mascotLoading
        ? const SizedBox(
            width: 150,
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          )
        : _buildMascotAvatar(width: 150, height: 150);

    return Scaffold(
      backgroundColor: const Color(0xFFebe8d6),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildResourceContainer(), // HUD (AuthService 구독)
                _buildSettingsButton(),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                SizedBox.expand(
                  child: DecorStage(
                    equipped: _equipped,
                    summerItems: _summer,
                    avatar: avatarWidget,
                    drawBorders: _gDebug.drawBorders,
                    scale: _gDebug.scale,
                    useHardcodedLayers: _gDebug.useHardcodedLayers,
                  ),
                ),
                if (_equippedLoading)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: showRandomMessage,
            child: Container(
              width: double.infinity,
              height: 120,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 30),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  currentMessage,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        height: 100,
        child: Row(
          children: [
            Expanded(
              child: _buildNavButton(
                Icons.calendar_today,
                "캘린더",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarPage()),
                ),
              ),
            ),
            Expanded(
              child: _buildNavButton(
                Icons.store,
                "상점",
                () async {
                  if (_equippedLoading || _userIdx == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('유저 정보를 불러오는 중입니다.')),
                    );
                    return;
                  }
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShopPage(
                        userIdx: _userIdx,
                        initialGamePoint:
                            (AuthService.instance.user?.gamePoint ?? widget.authUser.gamePoint),
                      ),
                    ),
                  );
                  await _afterReturnFromShop(result);
                },
              ),
            ),
            Expanded(
              child: _buildNavButton(
                Icons.brush,
                "꾸미기",
                () async {
                  if (_equippedLoading) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('유저 정보를 불러오는 중입니다.')),
                    );
                    return;
                  }
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DesignPage()),
                  );
                  await _afterReturnFromDesign(result);
                },
              ),
            ),
            Expanded(
              child: _buildNavButton(
                Icons.emoji_events,
                "퀘스트",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuestPage()),
                ).then((_) async {
                  // 퀘스트에서 보상 획득 시 최신값 반영
                  await AuthService.instance.refreshMe();
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 공통 위젯 =====

  // ✅ HUD: AuthService를 구독해서 자동 갱신
  Widget _buildResourceContainer() {
    return AnimatedBuilder(
      animation: AuthService.instance,
      builder: (context, _) {
        final u = AuthService.instance.user;
        if (u == null) {
          return const SizedBox(
            width: 160,
            child: Center(child: Text('로그인 필요', style: TextStyle(color: Colors.red))),
          );
        }

        const double maxExp = 1000.0;
        final widthFactor = (u.gameExp / maxExp).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (u.nickname?.trim().isNotEmpty ?? false) ? u.nickname! : (u.userId ?? 'Guest'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Image.asset(
                    "assets/images/coin.png",
                    width: 20,
                    height: 20,
                    errorBuilder: (c, e, s) =>
                        const Icon(Icons.monetization_on, color: Colors.yellow, size: 20),
                  ),
                  const SizedBox(width: 6),
                  Text("${u.gamePoint}",
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "EXP ${u.gameExp.toInt()}/${maxExp.toInt()}",
                style: const TextStyle(fontSize: 10, color: Colors.black),
              ),
              const SizedBox(height: 3),
              Container(
                height: 8,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widthFactor,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.lightGreen],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsButton() {
    return GestureDetector(
      onTap: _goToSettings,
      child: CircleAvatar(
        radius: 26,
        backgroundImage: const AssetImage("assets/images/1.png"),
        backgroundColor: Colors.white.withOpacity(0.7),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, String label, [VoidCallback? onTap]) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        padding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      onPressed: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

/// ================== 데코 스테이지(여름테마 목록 → 레이어 배치) ==================
class DecorStage extends StatelessWidget {
  const DecorStage({
    super.key,
    required this.equipped,
    required this.summerItems,
    this.avatar,
    this.drawBorders = false,
    this.scale = 1.0,
    this.useHardcodedLayers = false,
  });

  final Map<String, EquippedItem> equipped;
  final List<EquippedItem> summerItems;
  final Widget? avatar;

  final bool drawBorders;
  final double scale;
  final bool useHardcodedLayers;

  Widget _net(String? url, {BoxFit fit = BoxFit.contain}) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: drawBorders
          ? BoxDecoration(border: Border.all(color: Colors.redAccent, width: 1))
          : null,
      child: Image.network(
        url,
        fit: fit,
        loadingBuilder: (c, child, p) => p == null
            ? child
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (c, err, st) {
          return Container(
            color: Colors.black12,
            child: const Center(
              child: Icon(Icons.broken_image, size: 40),
            ),
          );
        },
      ),
    );
  }

  Map<String, String> _hardcodedLayerUrls() {
    final base = _gDebug.forcedBase;
    String abs(String p) => Uri.parse(base).replace(path: p.startsWith('/') ? p : '/$p').toString();
    return {
      '배경': abs('/img/roof.png'),
      '왼쪽': abs('/img/left.png'),
      '오른쪽': abs('/img/right.png'),
      '바닥': abs('/img/below.png'),
      '중앙': abs('/img/dolphin.png'),
      '전경': abs('/img/front.png'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final urls = useHardcodedLayers ? _hardcodedLayerUrls() : _urlsFromTheme(summerItems);

    final bg    = urls['배경'];
    final left  = urls['왼쪽'];
    final right = urls['오른쪽'];
    final floor = urls['바닥'];
    final mid   = urls['중앙'];
    final front = urls['전경'];

    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (ctx, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final sc = scale.clamp(1.0, 3.0);

          const double floorK = 1.35;

          return Stack(
            children: [
              if (bg != null) Positioned.fill(child: _net(bg, fit: BoxFit.cover)),

              if (left != null)
                Positioned(
                  left: w * 0.03, top: h * 0.35,
                  width:  w * (0.40 * sc),
                  height: h * (0.80 * sc),
                  child: _net(left),
                ),

              if (right != null)
                Positioned(
                  right: w * 0.02, top: h * 0.20,
                  width:  w * (0.50 * sc),
                  height: h * (0.80 * sc),
                  child: _net(right),
                ),

              if (floor != null)
                Positioned(
                  left: 0, right: 0, bottom: h * 0.12,
                  height: h * (0.22 * sc * floorK),
                  child: _net(floor, fit: BoxFit.cover),
                ),

              if (mid != null)
                Positioned(
                  left: w * 0.60, top: h * 0.25,
                  width:  w * (0.28 * sc),
                  height: w * (0.28 * sc),
                  child: _net(mid),
                ),

              if (front != null)
                Positioned(
                  left: w * 0.10, right: w * 0.10, bottom: h * 0.08,
                  height: h * (0.12 * sc),
                  child: _net(front, fit: BoxFit.contain),
                ),

              if (avatar != null)
                Positioned(
                  left: w * 0.34,
                  bottom: h * 0.18,
                  width:  w * (0.34 * sc),
                  height: w * (0.34 * sc),
                  child: FittedBox(fit: BoxFit.contain, child: avatar!),
                ),
            ],
          );
        },
      ),
    );
  }
}

// 설정 화면
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFebe8d6),
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingTile(
            icon: Icons.logout,
            title: '로그아웃',
            onTap: () async {
              await AuthService.instance.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
