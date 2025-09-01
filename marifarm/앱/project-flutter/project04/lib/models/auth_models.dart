// lib/models/auth_models.dart
import 'dart:convert';

class AuthUser {
  final String? memberIdx;   // PK (member_idx)
  final String? userId;      // 로그인 ID (user_id)
  final String? nickname;
  final List<String> roles;
  final int gamePoint;       // game_point
  final int gameExp;         // game_exp
  final int gameLevel;       // game_level

  const AuthUser({
    this.memberIdx,
    this.userId,
    this.nickname,
    this.roles = const [],
    this.gamePoint = 0,
    this.gameExp = 0,
    this.gameLevel = 1,
  });

  /// 불변 객체 갱신용
  AuthUser copyWith({
    String? memberIdx,
    String? userId,
    String? nickname,
    List<String>? roles,
    int? gamePoint,
    int? gameExp,
    int? gameLevel,
  }) {
    return AuthUser(
      memberIdx:  memberIdx  ?? this.memberIdx,
      userId:     userId     ?? this.userId,
      nickname:   nickname   ?? this.nickname,
      roles:      roles      ?? this.roles,
      gamePoint:  gamePoint  ?? this.gamePoint,
      gameExp:    gameExp    ?? this.gameExp,
      gameLevel:  gameLevel  ?? this.gameLevel,
    );
  }

  Map<String, dynamic> toMap() => {
    'memberIdx': memberIdx,
    'userId': userId,
    'nickname': nickname,
    'roles': roles,
    'gamePoint': gamePoint,
    'gameExp': gameExp,
    'gameLevel': gameLevel,
  };

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    int _toInt(dynamic v) => (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;

    // 서버가 예전 키를 내려주는 경우까지 대비한 fallback
    T? pick<T>(List<String> keys) {
      for (final k in keys) {
        if (map.containsKey(k) && map[k] != null) return map[k] as T;
      }
      return null;
    }

    return AuthUser(
      memberIdx: (pick(['memberIdx', 'id'])?.toString()),
      userId:    (pick(['userId', 'username'])?.toString()),
      nickname:  (pick(['nickname'])?.toString()),
      roles: (map['roles'] is List)
          ? (map['roles'] as List).map((e) => e.toString()).toList()
          : const [],
      gamePoint: _toInt(pick(['gamePoint','coins'])),
      gameExp:   _toInt(pick(['gameExp','exp'])),
      gameLevel: _toInt(pick(['gameLevel','level'])),
    );
  }
}

class AuthResponse {
  final String token;
  final AuthUser? user;

  AuthResponse({required this.token, this.user});

  factory AuthResponse.fromJson(String body) {
    final map = jsonDecode(body) as Map<String, dynamic>;
    final token = (map['token'] ?? '').toString();

    AuthUser? parsedUser;
    final rawUser = map['user'];
    if (rawUser is Map<String, dynamic>) {
      parsedUser = AuthUser.fromMap(rawUser);
    } else if (rawUser != null) {
      try {
        final parsed = jsonDecode(rawUser.toString());
        if (parsed is Map<String, dynamic>) {
          parsedUser = AuthUser.fromMap(parsed);
        }
      } catch (_) {}
    }

    return AuthResponse(token: token, user: parsedUser);
  }

  bool get hasToken => token.isNotEmpty;
}

class AuthResult {
  final bool success;
  final String? errorMessage;
  final AuthResponse? data;

  const AuthResult.success(this.data)
      : success = true, errorMessage = null;

  const AuthResult.failure(this.errorMessage)
      : success = false, data = null;
}
