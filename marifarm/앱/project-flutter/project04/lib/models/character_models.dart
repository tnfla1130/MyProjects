// lib/models/character_models.dart
import 'dart:convert';

/// 마스코트(캐릭터) 모델
class Mascot {
  final int charId;
  final int userIdx;
  final String name;        // char_name
  final String? face;       // 외형 코드 (예: 'seed', 'sprout' ...)
  final int? stage;         // 1~4 (서버가 토큰에서 계산해서 내려줌, 없으면 null)
  final DateTime? createdAt;

  Mascot({
    required this.charId,
    required this.userIdx,
    required this.name,
    this.face,
    this.stage,
    this.createdAt,
  });

  factory Mascot.fromMap(Map<String, dynamic> m) {
  int _i(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
  DateTime? _dt(dynamic v) => (v == null) ? null : DateTime.tryParse(v.toString());

  final charId  = _i(m['char_id']   ?? m['charId']   ?? m['id']);
  final userIdx = _i(m['user_idx']  ?? m['userIdx']  ?? m['member_idx']);

  // 서버에서 name이 null일 수도 → 빈 문자열로 통일(네 기존 로직 유지)
  final name = (m['char_name'] ?? m['name'] ?? '').toString();

  // ★ face_key도 함께 지원
  final face = (m['char_face'] ?? m['face'] ?? m['face_key'])?.toString();

  int? stage;
  final s = m['stage'] ?? m['mascot_stage'] ?? m['game_level'];
  if (s != null) {
    stage = _i(s);
    if (stage < 1) stage = 1;
    if (stage > 4) stage = 4;
  }

  final createdAt = _dt(m['created_at'] ?? m['createdAt']);

  return Mascot(
    charId: charId,
    userIdx: userIdx,
    name: name,
    face: face,
    stage: stage,
    createdAt: createdAt,
  );
}

  static Mascot fromJson(String body) =>
      Mascot.fromMap(jsonDecode(body) as Map<String, dynamic>);
}

/// 최초 생성/이름 변경 요청
class MascotNameRequest {
  final String name;
  MascotNameRequest(this.name);

  Map<String, dynamic> toJson() => {'name': name};
}

/// 외형 변경 요청(선택)
class MascotFaceRequest {
  final String face; // 예: 'seed' | 'sprout' | 'grown' | 'max'
  MascotFaceRequest(this.face);

  Map<String, dynamic> toJson() => {'face': face};
}
