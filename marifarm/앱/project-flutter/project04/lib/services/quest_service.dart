// lib/services/quest_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/quest_models.dart';
import '../services/auth_service.dart';

class QuestService {
  QuestService._();
  static final QuestService instance = QuestService._();

  static const _timeout = Duration(seconds: 12);

  String get baseUrl => AuthService.instance.baseUrl;

  Uri _listUri() => Uri.parse('$baseUrl/api/quest');
  Uri _meUri()   => Uri.parse('$baseUrl/api/quest/me');
  Uri _startUri(int questId)    => Uri.parse('$baseUrl/api/quest/$questId/start');
  Uri _completeUri(int questId) => Uri.parse('$baseUrl/api/quest/$questId/complete');
  Uri _attendanceUri()          => Uri.parse('$baseUrl/api/quest/attendance/check-in');

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /* ========== 목록 ========== */

  Future<List<Quest>> getQuests() async {
    final res = await http.get(_listUri(), headers: await _authHeaders()).timeout(_timeout);
      
    if (res.statusCode != 200) {
      throw Exception('퀘스트 목록 조회 실패 (${res.statusCode}) ${res.body}');
    }
    return Quest.listFromJson(res.body);
  }

  Future<List<UserQuest>> getMyUserQuests() async {
    final res = await http.get(_meUri(), headers: await _authHeaders()).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('내 퀘스트 상태 조회 실패 (${res.statusCode}) ${res.body}');
    }
    return UserQuest.listFromJson(res.body);
  }

  /* ========== 시작/완료 ========== */

  Future<bool> startQuest(int questId) async {
    final res = await http.post(_startUri(questId), headers: await _authHeaders()).timeout(_timeout);
    if (res.statusCode != 200) {
      throw Exception('퀘스트 시작 실패 (${res.statusCode}) ${res.body}');
    }
    final map = jsonDecode(res.body);
    return (map is Map<String, dynamic>) ? (map['success'] == true) : true;
  }

  /// 완료: 서버는 최종값만 내려줌 → 이전 캐시와 비교해 증가분 계산해서 돌려줌
  Future<QuestCompleteResult?> completeQuest(QuestCompleteRequest req, {Quest? expected}) async {
    final prevPoint = AuthService.instance.user?.gamePoint ?? 0;
    final prevExp   = AuthService.instance.user?.gameExp ?? 0;

    final res = await http.post(_completeUri(req.questId), headers: await _authHeaders()).timeout(_timeout);
    print('[QUEST LIST] ${res.statusCode} ${res.body}');
    if (res.statusCode != 200) {
      // 서버가 에러 메시지를 내려주면 그대로 노출
      try {
        final map = jsonDecode(res.body);
        final msg = (map is Map && map['error'] is String) ? map['error'] : '퀘스트 완료 실패';
        throw Exception(msg);
      } catch (_) {
        throw Exception('퀘스트 완료 실패 (${res.statusCode}) ${res.body}');
      }
    }

    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final result = QuestCompleteResult.fromMap(
      map,
      prevPoint: prevPoint,
      prevExp: prevExp,
      fallbackGold: expected?.rewardGold,
      fallbackExp: expected?.rewardExp,
    );

    // 캐시 최신화(가능하면)
    try {
      await AuthService.instance.fetchMe(silent: true);
    } catch (_) {}

    return result;
  }

  /* ========== 출석 전용 (퀘스트 엔드포인트 사용) ========== */
  /// 캘린더의 /api/calendar/attendance/check-in 이 이미 있다면 그쪽을 주로 쓰고,
  /// 굳이 퀘스트 쪽으로 처리하고 싶을 때만 호출.
  Future<QuestCompleteResult> attendanceCheckInViaQuest() async {
    final prevPoint = AuthService.instance.user?.gamePoint ?? 0;
    final prevExp   = AuthService.instance.user?.gameExp ?? 0;
    
    
    final res = await http.post(_attendanceUri(), headers: await _authHeaders()).timeout(_timeout);

    print('[QUEST LIST] ${res.statusCode} ${res.body}');
    if (res.statusCode != 200) {
      throw Exception('출석(퀘스트) 실패 (${res.statusCode}) ${res.body}');
    }
    final map = jsonDecode(res.body) as Map<String, dynamic>;
    final result = QuestCompleteResult.fromMap(map, prevPoint: prevPoint, prevExp: prevExp);

    try { await AuthService.instance.fetchMe(silent: true); } catch (_) {}

    return result;
  }
}
