import 'dart:convert';

class CalendarPhotoMeta {
  final DateTime takenAt;
  final String filePath;
  final String fileName;
  final String contentType;
  final int fileSize;
  final String? checksumSha256;
  final int? width;
  final int? height;
  final String? tagsJson;
  final String? exifJson;

  CalendarPhotoMeta({
    required this.takenAt,
    required this.filePath,
    required this.fileName,
    required this.contentType,
    required this.fileSize,
    this.checksumSha256,
    this.width,
    this.height,
    this.tagsJson,
    this.exifJson,
  });

  /// 서버가 기대하는 키 그대로 Map으로 반환 (절대 직접 jsonEncode하지 말 것)
  Map<String, dynamic> toJson() => {
        "takenAt": takenAt.toIso8601String(),
        "filePath": filePath,
        "fileName": fileName,
        "contentType": contentType,
        "fileSize": fileSize,
        if (checksumSha256 != null) "checksumSha256": checksumSha256,
        if (width != null) "width": width,
        if (height != null) "height": height,
        if (tagsJson != null) "tagsJson": tagsJson,
        if (exifJson != null) "exifJson": exifJson,
      };
}

class CalendarPhotoResponse {
  final bool success;
  final int? photoId;

  /// 서버는 사진 업로드 응답에서 day_key(YYYY-MM-DD)를 내려줌.
  /// 과거 호환을 위해 window_key도 같이 읽어줌.
  final String? dayKey;

  final DateTime? takenAt;
  final String? filePath;
  final String? fileName;
  final String? contentType;
  final int? fileSize;
  final DateTime? createdAt;

  /// 사진 퀘스트 완료 여부(멱등)
  final bool photoQuestCompleted;

  /// 퀘스트 완료 시 내려오는 보상 반영 후 스탯(없을 수 있음)
  final int? gamePoint;
  final int? gameExp;
  final int? gameLevel;

  /// 선택적으로 내려올 수 있는 메시지
  final String? questMessage;

  CalendarPhotoResponse({
    required this.success,
    this.photoId,
    this.dayKey,
    this.takenAt,
    this.filePath,
    this.fileName,
    this.contentType,
    this.fileSize,
    this.createdAt,
    this.photoQuestCompleted = false,
    this.gamePoint,
    this.gameExp,
    this.gameLevel,
    this.questMessage,
  });

  factory CalendarPhotoResponse.fromMap(Map<String, dynamic> m) {
    int? _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v');
    DateTime? _dt(dynamic v) => (v == null) ? null : DateTime.tryParse(v.toString());

    // day_key 우선, window_key는 백워드 호환
    final _dayKey = (m['day_key'] ?? m['window_key'])?.toString();

    return CalendarPhotoResponse(
      success: m['success'] == true,
      photoId: _i(m['photo_id']),
      dayKey: _dayKey,
      takenAt: _dt(m['taken_at']),
      filePath: m['file_path']?.toString(),
      fileName: m['file_name']?.toString(),
      contentType: m['content_type']?.toString(),
      fileSize: _i(m['file_size']),
      createdAt: _dt(m['created_at']),
      photoQuestCompleted: m['photo_quest_completed'] == true,
      gamePoint: _i(m['game_point']),
      gameExp: _i(m['game_exp']),
      gameLevel: _i(m['game_level']),
      questMessage: m['quest_message']?.toString(),
    );
  }

  factory CalendarPhotoResponse.fromJson(String body) =>
      CalendarPhotoResponse.fromMap(jsonDecode(body) as Map<String, dynamic>);
}

class AttendanceCheckInResponse {
  final bool firstCheckToday;
  final String windowKey; // YYYY-MM-DD
  final int gamePoint;
  final int gameExp;
  final int gameLevel;

  AttendanceCheckInResponse({
    required this.firstCheckToday,
    required this.windowKey,
    required this.gamePoint,
    required this.gameExp,
    required this.gameLevel,
  });

  factory AttendanceCheckInResponse.fromJson(String body) {
    final m = jsonDecode(body) as Map<String, dynamic>;
    int _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
    return AttendanceCheckInResponse(
      firstCheckToday: m['first_check_today'] == true,
      windowKey: (m['window_key'] ?? '').toString(),
      gamePoint: _i(m['game_point']),
      gameExp: _i(m['game_exp']),
      gameLevel: _i(m['game_level']),
    );
  }
}
