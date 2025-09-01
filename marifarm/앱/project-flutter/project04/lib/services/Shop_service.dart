// services/shop_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/shop_models.dart';
import 'auth_service.dart'; // JWT 토큰 가져오기용

class ShopService {
  static const String baseUrl = 'http://192.168.0.39:8080/api/shop';

  // 이미지 절대경로 변환
  static const String _serverOrigin = 'http://192.168.0.39:8080';
  static String imageUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '$_serverOrigin$url';
  }

  static const Duration _timeout = Duration(seconds: 8);

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.instance.getToken();
    return {
      'Content-Type': 'application/json; charset=utf-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// 미구매 상점 아이템 전체 조회
  /// GET /api/shop/items   (백엔드에 엔드포인트가 있다면 사용)
  static Future<List<ShopItem>> getAvailableItems() async {
    try {
      final url = Uri.parse('$baseUrl/items');
      final res = await http.get(url, headers: await _headers()).timeout(_timeout);

      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((e) => ShopItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed: ${res.statusCode}');
    } catch (e) {
      print('getAvailableItems error: $e');
      return [];
    }
  }

  /// 테마별 미구매 아이템 조회
  /// GET /api/shop/items/thema/{thema}
  static Future<List<ShopItem>> getItemsByThema(String thema) async {
    try {
      final uri = Uri.parse('$baseUrl/items/thema/${Uri.encodeComponent(thema)}');
      print('[SHOP] GET $uri');
      final res = await http.get(uri, headers: await _headers()).timeout(_timeout);
      print('[SHOP] status=${res.statusCode}');

      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((e) => ShopItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed: ${res.statusCode}');
    } catch (e) {
      print('getItemsByThema error: $e');
      return [];
    }
  }

  /// 구매 요청 (백엔드: POST /api/shop/purchase/{itemId})
  static Future<PurchaseResult> purchaseItem(int itemId) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase/$itemId'); // ← PathVariable 방식으로 변경
      final headers = await _headers();
      print('[SHOP] POST $uri  token.len=${(headers['Authorization'] ?? '').length}');

      final res = await http
          .post(uri, headers: headers)                // ← body 없음
          .timeout(_timeout);

      print('[SHOP] status=${res.statusCode} body=${res.body}');
      if (res.statusCode == 200) {
        final result = PurchaseResult.fromJson(json.decode(utf8.decode(res.bodyBytes)));
        if (result.success) {
          // ✅ 구매 성공했으면 최신 잔액/경험치 재조회 → 전역 상태 notify
         await AuthService.instance.fetchMe(silent: true);      
         }        
         return result;

      }
      return _parsePurchaseResult(res);
    } on TimeoutException {
      return PurchaseResult(success: false, message: '요청 시간이 초과되었습니다.', remainingGold: 0);
    } catch (e) {
      print('purchaseItem error: $e');
      return PurchaseResult(success: false, message: '네트워크 오류가 발생했습니다.', remainingGold: 0);
    }
  }

  /// (참고용) 만약 바디로 보내는 서버 버전이 따로 생기면 이 메서드 사용
  static Future<PurchaseResult> purchaseItemWithBody(int itemId) async {
    try {
      final uri = Uri.parse('$baseUrl/purchase');
      final headers = await _headers();
      print('[SHOP] POST $uri (body) token.len=${(headers['Authorization'] ?? '').length}');

      final res = await http
          .post(uri, headers: headers, body: json.encode({'itemId': itemId}))
          .timeout(_timeout);

      print('[SHOP] status=${res.statusCode} body=${res.body}');
      if (res.statusCode == 200) {
        return PurchaseResult.fromJson(json.decode(utf8.decode(res.bodyBytes)));
      }
      return _parsePurchaseResult(res);
    } on TimeoutException {
      return PurchaseResult(success: false, message: '요청 시간이 초과되었습니다.', remainingGold: 0);
    } catch (e) {
      print('purchaseItemWithBody error: $e');
      return PurchaseResult(success: false, message: '네트워크 오류가 발생했습니다.', remainingGold: 0);
    }
  }

  /// 구매 결과 파싱 (에러 시에도 메시지 처리)
  static PurchaseResult _parsePurchaseResult(http.Response res) {
    try {
      final body = json.decode(utf8.decode(res.bodyBytes));
      return PurchaseResult.fromJson(body as Map<String, dynamic>);
    } catch (_) {
      return PurchaseResult(
        success: false,
        message: '구매 처리 실패: HTTP ${res.statusCode}',
        remainingGold: 0,
      );
    }
  }

  /// 내 구매 목록
  /// GET /api/shop/purchases
  static Future<List<UserPurchase>> getUserPurchases() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/purchases'), headers: await _headers())
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final List<dynamic> list = json.decode(utf8.decode(res.bodyBytes));
        return list.map((e) => UserPurchase.fromJson(e as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed: ${res.statusCode}');
    } catch (e) {
      print('getUserPurchases error: $e');
      return [];
    }
  }

  /// 특정 아이템 구매 여부 확인
  /// GET /api/shop/check?itemId={id}   (백엔드에 엔드포인트가 있다면 사용)
  static Future<bool> checkItemPurchased(int itemId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/check?itemId=$itemId'), headers: await _headers())
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        return (data['hasPurchased'] == true);
      }
      return false;
    } catch (e) {
      print('checkItemPurchased error: $e');
      return false;
    }
  }
}
