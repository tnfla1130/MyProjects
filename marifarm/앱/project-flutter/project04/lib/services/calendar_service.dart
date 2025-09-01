// lib/services/calendar_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart'; // kDebugMode, debugPrint
import 'package:http/http.dart' as http;

import '../models/calendar_models.dart';
import '../services/auth_service.dart';

/// 캘린더/출석 관련 API 클라이언트
class CalendarService {
  CalendarService._();
  static final CalendarService instance = CalendarService._();

  static const _timeout = Duration(seconds: 12);

  String get baseUrl => AuthService.instance.baseUrl;

  Uri get _uploadPhotoUri => Uri.parse('$baseUrl/api/calendar/photos');
  Uri get _checkInUri => Uri.parse('$baseUrl/api/calendar/attendance/check-in');

  /// 공통 인증 헤더
  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 디버그 로그에서 토큰 일부만 보이도록 마스킹
  String _maskToken(String? authHeader) {
    if (authHeader == null) return '';
    final t = authHeader.replaceFirst('Bearer ', '');
    if (t.length <= 10) return '***';
    return '${t.substring(0, 6)}...${t.substring(t.length - 4)}';
  }

  /// 사진 "메타" 업로드 (파일 자체 업로드는 별도 API/스토리지 필요)
  ///
  /// 서버 엔드포인트: POST /api/calendar/photos
  /// Body: JSON (CalendarPhotoMeta.toJson())
  /// Header: Authorization: Bearer <token>, Content-Type: application/json
  ///
  /// 성공 시 CalendarPhotoResponse 반환.
  Future<CalendarPhotoResponse> uploadPhotoMeta(CalendarPhotoMeta meta) async {
    final headers = await _authHeaders();
    final body = jsonEncode(meta.toJson()); // ✅ 반드시 JSON 인코딩
    final uri = _uploadPhotoUri;

    if (kDebugMode) {
      final masked = Map<String, String>.from(headers);
      if (masked['Authorization'] != null) {
        masked['Authorization'] = 'Bearer ${_maskToken(masked['Authorization'])}';
      }
      debugPrint('[CAL UPLOAD][REQ] POST $uri');
      debugPrint('[CAL UPLOAD][HEAD] $masked');
      debugPrint('[CAL UPLOAD][BODY] $body');
    }

    try {
      final res = await http
          .post(uri, headers: headers, body: body)
          .timeout(_timeout);

      if (kDebugMode) {
        debugPrint('[CAL UPLOAD][RES] ${res.statusCode} ${res.body}');
      }

      if (res.statusCode != 200) {
        throw Exception('사진 메타 업로드 실패 (${res.statusCode}) ${res.body}');
      }
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return CalendarPhotoResponse.fromMap(map);
    } on TimeoutException {
      debugPrint('[CAL UPLOAD][ERR] timeout');
      rethrow;
    } catch (e) {
      debugPrint('[CAL UPLOAD][ERR] $e');
      rethrow;
    }
  }

  /// 출석 체크 (오늘 1회 멱등)
  ///
  /// 서버 엔드포인트: POST /api/calendar/attendance/check-in
  /// Query: source/memo (옵션)
  /// Header: Authorization: Bearer <token>
  ///
  /// 성공 시 AttendanceCheckInResponse 반환.
  Future<AttendanceCheckInResponse> checkIn({
    String? source,
    String? memo,
  }) async {
    // 쿼리 파라미터 안전 구성
    Uri uri = _checkInUri;
    final qp = <String, String>{};
    if (source != null) qp['source'] = source;
    if (memo != null) qp['memo'] = memo;
    if (qp.isNotEmpty) {
      uri = uri.replace(queryParameters: qp);
    }

    final headers = await _authHeaders();

    if (kDebugMode) {
      final masked = Map<String, String>.from(headers);
      if (masked['Authorization'] != null) {
        masked['Authorization'] = 'Bearer ${_maskToken(masked['Authorization'])}';
      }
      debugPrint('[ATTEND][REQ] POST $uri');
      debugPrint('[ATTEND][HEAD] $masked');
    }

    try {
      final res = await http.post(uri, headers: headers).timeout(_timeout);

      if (kDebugMode) {
        debugPrint('[ATTEND][RES] ${res.statusCode} ${res.body}');
      }

      if (res.statusCode != 200) {
        throw Exception('출석 체크 실패 (${res.statusCode}) ${res.body}');
      }
      return AttendanceCheckInResponse.fromJson(res.body);
    } on TimeoutException {
      debugPrint('[ATTEND][ERR] timeout');
      rethrow;
    } catch (e) {
      debugPrint('[ATTEND][ERR] $e');
      rethrow;
    }
  }
}
