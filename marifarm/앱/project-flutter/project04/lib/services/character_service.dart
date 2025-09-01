// lib/services/character_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/character_models.dart';
import '../services/auth_service.dart';

class CharacterService {
  CharacterService._();
  static final CharacterService instance = CharacterService._();

  static const _timeout = Duration(seconds: 12);

  String get baseUrl => AuthService.instance.baseUrl;

  Uri get _meUri   => Uri.parse('$baseUrl/api/character/me');
  Uri get _nameUri => Uri.parse('$baseUrl/api/character/name');

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /* ========== 조회 (서버가 get-or-create 수행) ========== */

  /// 내 마스코트 조회 (없어도 서버가 생성해서 내려줌)
  Future<Mascot> getMyMascot() async {
    final res = await http.get(_meUri, headers: await _authHeaders()).timeout(_timeout);

    if (kDebugMode) {
      debugPrint('[MASCOT][GET] ${res.statusCode} ${res.body}');
    }

    if (res.statusCode == 200) {
      return Mascot.fromJson(res.body);
    }
    throw Exception('마스코트 조회 실패 (${res.statusCode}) ${res.body}');
  }

  /// 이름이 비어 있으면 true (첫 로그인 시 입력 폼 노출 용)
  Future<bool> needsName() async {
    final m = await getMyMascot();
    return m.name.trim().isEmpty;
  }

  /* ========== 최초 1회 이름 등록 ========== */

  /// 이름 최초 등록(이미 있으면 409)
  Future<Mascot> registerNameOnce(String name) async {
    final body = jsonEncode({'name': name});

    final res = await http
        .post(_nameUri, headers: await _authHeaders(), body: body)
        .timeout(_timeout);

    if (kDebugMode) {
      debugPrint('[MASCOT][REGISTER_NAME] ${res.statusCode} ${res.body}');
    }

    if (res.statusCode == 200) {
      // 일부 응답이 name/stage만 포함할 수 있으니, 항상 전체 상태 재조회
      return await getMyMascot();
    }
    if (res.statusCode == 409) {
      throw Exception('이미 이름이 등록된 캐릭터입니다.');
    }
    if (res.statusCode == 400) {
      throw Exception('유효하지 않은 이름입니다.');
    }
    throw Exception('이름 등록 실패 (${res.statusCode}) ${res.body}');
  }

  /// 보조: 이름이 없으면 등록하고, 있으면 그대로 반환
  Future<Mascot> ensureNameRegistered(String nameIfEmpty) async {
    final m = await getMyMascot();
    if (m.name.trim().isEmpty) {
      return await registerNameOnce(nameIfEmpty);
    }
    return m;
  }
}
