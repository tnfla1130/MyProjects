import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/decor_models.dart';
import 'auth_service.dart';

class DecorService {
  static const Duration _timeout = Duration(seconds: 10);

  static Future<Uri> _u(String path, {Map<String, dynamic>? query}) async {
    final base = AuthService.instance.baseUrl;
    final uri = Uri.parse('$base$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((k, v) => MapEntry(k, '$v')),
    });
  }

  static Future<Map<String, String>> _headers({bool jsonBody = false}) async {
    final t = await AuthService.instance.getToken();
    return {
      if (jsonBody) 'Content-Type': 'application/json; charset=utf-8',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  static Future<http.Response> _get(Uri uri) async =>
      http.get(uri, headers: await _headers()).timeout(_timeout);

  static Future<http.Response> _post(Uri uri, {Object? body}) async =>
      http
          .post(uri,
              headers: await _headers(jsonBody: body != null),
              body: body == null ? null : jsonEncode(body))
          .timeout(_timeout);

  static Future<http.Response> _delete(Uri uri) async =>
    http.delete(uri, headers: await _headers()).timeout(_timeout);

  static bool _ok(http.Response r) => r.statusCode >= 200 && r.statusCode < 300;

  /// 인벤토리(구매목록 + 장착여부)
  /// GET /api/decor/inventory?slot=배경
  static Future<List<DecorInventoryItem>> getInventory({String? slot}) async {
    final uri = await _u('/api/decor/inventory',
        query: {if (slot?.isNotEmpty == true) 'slot': slot});
    try {
      final res = await _get(uri);
      if (_ok(res)) {
        final List list = json.decode(utf8.decode(res.bodyBytes));
        return list
            .whereType<Map<String, dynamic>>()
            .map(DecorInventoryItem.fromJson)
            .toList();
      }
      throw Exception('getInventory failed: ${res.statusCode} ${res.reasonPhrase}');
    } on TimeoutException {
      print('getInventory timeout');
      return [];
    } catch (e) {
      print('getInventory error: $e');
      return [];
    }
  }

  /// 현재 장착 (slot -> List<EquippedItem>)
  /// GET /api/decor/equipped
  static Future<Map<String, List<EquippedItem>>> getEquipped() async {
    final uri = await _u('/api/decor/equipped');
    try {
      final res = await _get(uri);
      if (_ok(res)) {
        final Map<String, dynamic> map = json.decode(utf8.decode(res.bodyBytes));
        return parseEquippedBuckets(map);
      }
      throw Exception('getEquipped failed: ${res.statusCode} ${res.body}');
    } on TimeoutException {
      print('getEquipped timeout');
      return {};
    } catch (e) {
      print('getEquipped error: $e');
      return {};
    }
  }

  /// 장착(중복 허용) — POST /api/decor/equip { itemId, slot? }
  static Future<bool> equip(int itemId, {String? slot}) async {
    try {
      final uri = await _u('/api/decor/equip');
      final res = await _post(uri, body: {'itemId': itemId, if (slot != null) 'slot': slot});
      if (_ok(res)) return true;
      print('equip fail: ${res.statusCode} ${res.body}');
      return false;
    } on TimeoutException {
      print('equip timeout');
      return false;
    } catch (e) {
      print('equip error: $e');
      return false;
    }
  }

  /// 해제 — DELETE /api/decor/equip/{slot}?itemId=123
  /// itemId 없으면 슬롯 전체 해제
  static Future<bool> unequip(String slot, {int? itemId}) async {
    try {
      final uri = await _u('/api/decor/equip/${Uri.encodeComponent(slot)}',
          query: {if (itemId != null) 'itemId': itemId});
      final res = await _delete(uri);
      if (_ok(res)) return true;
      print('unequip fail: ${res.statusCode} ${res.body}');
      return false;
    } on TimeoutException {
      print('unequip timeout');
      return false;
    } catch (e) {
      print('unequip error: $e');
      return false;
    }
  }

  /// 렌더링 헬퍼: 한 번에 equipped + inventory(slot) 업데이트
  static Future<DecorSnapshot> refreshForSlot(String? slot) async {
    try {
      final equipped = await getEquipped();
      final inventory = await getInventory(slot: slot);
      return DecorSnapshot(
        equippedBySlot: equipped,
        inventoryForSlot: inventory,
      );
    } catch (e) {
      print('refreshForSlot error: $e');
      return const DecorSnapshot(equippedBySlot: {}, inventoryForSlot: []);
    }
  }
}
