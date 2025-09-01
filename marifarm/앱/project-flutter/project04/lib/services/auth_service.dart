// lib/services/auth_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../models/auth_models.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _timeout = Duration(seconds: 10);
  static const _tokenKey = 'jwt_token';

  /// 메모리 캐시된 로그인 사용자
  AuthUser? _user;
  AuthUser? get user => _user;

  /// ✅ UI 실시간 반영용 (ValueListenableBuilder로 구독)
  final ValueNotifier<AuthUser?> currentUser = ValueNotifier<AuthUser?>(null);

  String get baseUrl =>
      Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://192.168.0.39:8080';

  Uri get _loginUri => Uri.parse('$baseUrl/api/auth/login');
  Uri get _meUri    => Uri.parse('$baseUrl/api/auth/me'); // 서버의 /me 엔드포인트

  /// 외부에서 공통 헤더 쉽게 사용
  Future<Map<String, String>> headers() => _authHeaders();

  /// 공통 인증 헤더
  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// ✅ 내부 상태 세팅 + 알림 (항상 이것만 사용)
  void setUser(AuthUser? u) {
    _user = u;
    currentUser.value = u;   // ValueListenable 구독자 갱신
    notifyListeners();       // ChangeNotifier 구독자 갱신
  }

  /// ✅ HUD 수치 부분 갱신 (불변 객체 교체)
  void applyMePatch({
    int? gamePoint,
    int? gameExp,
    int? gameLevel,
    String? nickname,
  }) {
    final u = _user;
    if (u == null) return;

    final patched = u.copyWith(
      gamePoint: gamePoint,
      gameExp:   gameExp,
      gameLevel: gameLevel,
      nickname:  nickname,
    );

    setUser(patched); // 내부에서 ValueNotifier/ChangeNotifier 모두 알림
  }

  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await http
          .post(
            _loginUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password,
            }),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        late final AuthResponse auth;
        try {
          auth = AuthResponse.fromJson(res.body);
        } catch (_) {
          return const AuthResult.failure('서버 응답 형식이 올바르지 않습니다.');
        }

        if (!auth.hasToken) {
          return const AuthResult.failure('토큰을 받지 못했습니다.');
        }

        // 토큰 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, auth.token);

        // 1차 사용자 세팅
        setUser(auth.user);

        // 2차: /me로 최신 사용자 정보 덮어쓰기(있으면)
        try {
          final refreshed = await fetchMe(silent: true);
          if (refreshed != null) setUser(refreshed);
        } catch (_) {
          // 조용히 무시
        }

        return AuthResult.success(auth);
      } else {
        String msg = '로그인 실패 (${res.statusCode})';
        try {
          final err = jsonDecode(res.body);
          if (err is Map && err['error'] is String) {
            msg = err['error'];
          }
        } catch (_) {}
        return AuthResult.failure(msg);
      }
    } on TimeoutException {
      return const AuthResult.failure('서버 응답 시간이 초과되었습니다.');
    } catch (e) {
      return AuthResult.failure('네트워크 오류: $e');
    }
  }

  /// 현재 사용자 토큰 기반으로 서버에서 내 정보 재조회
  Future<AuthUser?> fetchMe({bool silent = false}) async {
    try {
      final res = await http
          .get(_meUri, headers: await _authHeaders())
          .timeout(_timeout);

      if (!silent) {
        // print('[ME RAW BODY] ${res.statusCode} ${res.body}');
      }

      if (res.statusCode == 200) {
        final map = jsonDecode(res.body);
        Map<String, dynamic>? userMap;
        if (map is Map<String, dynamic>) {
          userMap = (map['user'] is Map<String, dynamic>) ? map['user'] : map;
        }
        if (userMap == null) return null;

        final me = AuthUser.fromMap(userMap);
        setUser(me); // ✅ notify 포함
        return me;
      }
      return null;
    } catch (e) {
      if (!silent) {
        // print('[ME ERROR] $e');
      }
      return null;
    }
  }

  /// ✅ refreshMe 별칭 (mainPage 등에서 호출 가능)
  Future<void> refreshMe() async {
    await fetchMe(silent: true);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    setUser(null); // ✅ notify 포함
  }

  Future<bool> hasValidToken() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }
}
