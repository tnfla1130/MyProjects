import 'dart:convert';

enum QuestType { dailyAttendance, dailyPhoto, unknown }

QuestType questTypeFrom(dynamic v) {
  final s = v?.toString().toUpperCase() ?? '';
  switch (s) {
    case 'DAILY_ATTENDANCE':
      return QuestType.dailyAttendance;
    case 'DAILY_PHOTO':
      return QuestType.dailyPhoto;
    default:
      return QuestType.unknown;
  }
}

class Quest {
  final int questId;
  final QuestType questType;
  final String questName;
  final String description;
  final int rewardGold;
  final int rewardExp;
  final bool active;

  Quest({
    required this.questId,
    required this.questType,
    required this.questName,
    required this.description,
    required this.rewardGold,
    required this.rewardExp,
    required this.active,
  });

  factory Quest.fromMap(Map<String, dynamic> map) {
    int _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
    bool _b(dynamic v) {
      if (v is bool) return v;
      final s = v?.toString().toLowerCase();
      return s == '1' || s == 'true' || s == 'y';
    }

    return Quest(
      questId: _i(map['quest_id'] ?? map['questId'] ?? map['id']),
      questType: questTypeFrom(map['quest_type'] ?? map['questType']),
      questName: (map['name'] ?? map['quest_name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      rewardGold: _i(map['reward_gold'] ?? map['rewardGold']),
      rewardExp: _i(map['reward_exp'] ?? map['rewardExp']),
      active: _b(map['active'] ?? true),
    );
  }

  static List<Quest> listFromJson(String body) {
    final raw = jsonDecode(body);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Quest.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}

class UserQuest {
  final int userIdx;
  final int questId;
  final String status;           // 'n' or 'y'
  final String? windowKey;       // YYYY-MM-DD
  final DateTime? completedAt;
  final int progressCount;

  UserQuest({
    required this.userIdx,
    required this.questId,
    required this.status,
    this.windowKey,
    this.completedAt,
    this.progressCount = 0,
  });

  factory UserQuest.fromMap(Map<String, dynamic> map) {
    int _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
    DateTime? _dt(dynamic v) => (v == null) ? null : DateTime.tryParse(v.toString());

    // id가 {userIdx, questId} 로 오는 JPA 케이스 대비
    final id = (map['id'] is Map) ? Map<String, dynamic>.from(map['id']) : const {};
    final _userIdx = map['user_idx'] ?? map['userIdx'] ?? id['userIdx'];
    final _questId = map['quest_id'] ?? map['questId'] ?? id['questId'];

    return UserQuest(
      userIdx: _i(_userIdx),
      questId: _i(_questId),
      status: (map['status'] ?? 'n').toString(),
      windowKey: (map['window_key'] ?? map['windowKey'])?.toString(),
      completedAt: _dt(map['completed_at'] ?? map['completedAt']),
      progressCount: _i(map['progress_count'] ?? map['progressCount']),
    );
  }

  static List<UserQuest> listFromJson(String body) {
    final raw = jsonDecode(body);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => UserQuest.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }
}

/// (UI에서 그대로 쓰는 요청 래퍼 — 서버는 바디를 안 받아도 PATH로 동작)
class QuestCompleteRequest {
  final int userIdx; // 참고용
  final int questId;

  QuestCompleteRequest({required this.userIdx, required this.questId});
}

/// 완료 응답 + 델타(증가분) 계산 결과
class QuestCompleteResult {
  final bool success;
  final int newGamePoint;
  final int newExp;
  final int newLevel;
  final int goldGained; // 계산된 증가분(추정)
  final int expGained;  // 계산된 증가분(추정)

  QuestCompleteResult({
    required this.success,
    required this.newGamePoint,
    required this.newExp,
    required this.newLevel,
    required this.goldGained,
    required this.expGained,
  });

  factory QuestCompleteResult.fromMap(
    Map<String, dynamic> map, {
    int? prevPoint,
    int? prevExp,
    int? fallbackGold, // 서버가 증가분을 안 주므로 추정값(예: quest.rewardGold)
    int? fallbackExp,  // 마찬가지
  }) {
    int _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

    final success = (map['success'] ?? false) == true;
    final newPoint = _i(map['game_point']);
    final newExp   = _i(map['game_exp']);
    final newLevel = _i(map['game_level']);

    final deltaPoint = (prevPoint != null) ? (newPoint - prevPoint).clamp(0, 1 << 31) : (fallbackGold ?? 0);
    final deltaExp   = (prevExp   != null) ? (newExp   - prevExp).clamp(0, 1 << 31) : (fallbackExp ?? 0);

    return QuestCompleteResult(
      success: success,
      newGamePoint: newPoint,
      newExp: newExp,
      newLevel: newLevel,
      goldGained: deltaPoint,
      expGained: deltaExp,
    );
  }
}
