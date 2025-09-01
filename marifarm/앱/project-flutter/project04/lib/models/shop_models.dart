int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

class ShopItem {
  final int itemId;
  final String itemName;
  final String description;
  final int priceGold;
  final String thema; // 서버 필드명 그대로
  final String url;

  ShopItem({
    required this.itemId,
    required this.itemName,
    required this.description,
    required this.priceGold,
    required this.thema,
    required this.url,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      itemId: _asInt(json['itemId']),
      itemName: json['itemName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priceGold: _asInt(json['priceGold']),
      thema: json['thema']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }
}

// 서버 DTO: UserPurchaseDto { Long itemId; Date purchasedAt; }
class UserPurchase {
  final int itemId;
  final String purchasedAt; // ISO 문자열 그대로

  UserPurchase({
    required this.itemId,
    required this.purchasedAt,
  });

  factory UserPurchase.fromJson(Map<String, dynamic> json) {
    return UserPurchase(
      itemId: _asInt(json['itemId']),
      purchasedAt: json['purchasedAt']?.toString() ?? '',
    );
  }
}

class PurchaseResult {
  final bool success;
  final String message;
  final int remainingGold;

  PurchaseResult({
    required this.success,
    required this.message,
    required this.remainingGold,
  });

  factory PurchaseResult.fromJson(Map<String, dynamic> json) {
    return PurchaseResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      remainingGold: _asInt(json['remainingGold']),
    );
  }
}
