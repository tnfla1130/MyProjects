int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

bool _asBoolYN(dynamic v) {
  if (v is bool) return v;
  final s = v?.toString().toLowerCase();
  return s == 'y' || s == 'yes' || s == 'true' || s == '1';
}

/// 인벤토리(구매목록 + 장착여부) 한 줄
/// 서버 DecorController.getInventory 응답:
/// itemId, itemName, description, priceGold, slot, url, equipped
class DecorInventoryItem {
  final int itemId;
  final String itemName;
  final String description;
  final int priceGold;
  final String slot; // = thema
  final String url;
  final bool equipped;

  DecorInventoryItem({
    required this.itemId,
    required this.itemName,
    required this.description,
    required this.priceGold,
    required this.slot,
    required this.url,
    required this.equipped,
  });

  factory DecorInventoryItem.fromJson(Map<String, dynamic> json) {
    return DecorInventoryItem(
      itemId: _asInt(json['itemId']),
      itemName: json['itemName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priceGold: _asInt(json['priceGold']),
      slot: json['slot']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
      equipped: _asBoolYN(json['equipped']),
    );
  }
}

/// 현재 장착 항목(단일)
class EquippedItem {
  final String slot;
  final int itemId;
  final String url;

  EquippedItem({
    required this.slot,
    required this.itemId,
    required this.url,
  });

  factory EquippedItem.fromJson(Map<String, dynamic> json) {
    return EquippedItem(
      slot: json['slot']?.toString() ?? '',
      itemId: _asInt(json['itemId']),
      url: json['url']?.toString() ?? '',
    );
  }
}

/// 서버 응답: { "배경": [ {...}, {...} ], "벽": [ ... ], ... }
Map<String, List<EquippedItem>> parseEquippedBuckets(Map<String, dynamic> json) {
  final result = <String, List<EquippedItem>>{};
  json.forEach((key, value) {
    if (value is List) {
      result[key] = value
          .whereType<Map<String, dynamic>>()
          .map(EquippedItem.fromJson)
          .toList();
    } else if (value is Map<String, dynamic>) {
      // 혹시 단일 객체로 내려오면 방어
      result[key] = [EquippedItem.fromJson(value)];
    }
  });
  return result;
}

/// 화면 렌더링 스냅샷 (equipped + inventory)
class DecorSnapshot {
  final Map<String, List<EquippedItem>> equippedBySlot;
  final List<DecorInventoryItem> inventoryForSlot;

  const DecorSnapshot({
    required this.equippedBySlot,
    required this.inventoryForSlot,
  });
}
