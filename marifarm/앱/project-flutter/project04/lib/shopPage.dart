// shop_page.dart
import 'package:flutter/material.dart';
import 'services/shop_service.dart';
import 'models/shop_models.dart';

// ✅ 전역 사용자 상태 구독
import 'services/auth_service.dart';
import 'models/auth_models.dart';

class ShopPage extends StatefulWidget {
  final int userIdx; // 외형상 유지(현재 백엔드는 토큰으로 판별)
  final int initialGamePoint; // 사용 안 해도 무방(전역 구독으로 대체)

  const ShopPage({
    super.key,
    required this.userIdx,
    required this.initialGamePoint,
  });

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with TickerProviderStateMixin {
  static const Color green = Color(0xFF8FBC8F);
  static const Color olive = Color(0xFF6B8E23);

  // ✅ 로컬 코인 제거 / 전역 구독 사용
  final Set<int> _purchased = <int>{};
  Map<String, List<ShopItem>> _shopItemsByThema = <String, List<ShopItem>>{};
  bool _isLoading = true;

  bool _isBuying = false;
  int? _buyingItemId;

  late List<ThemeInfo> _themeInfos;
  int _selectedThemeIndex = 0;

  @override
  void initState() {
    super.initState();

    _themeInfos = <ThemeInfo>[
      ThemeInfo(
        name: '여름테마',
        themaKey: '여름테마',
        description: '여름한정 테마',
        bannerColor: green,
        emoji: '🌱',
      ),
    ];

    _loadShopData();
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);
    try {
      // ⬇️ 테마별 아이템 로드
      for (final themeInfo in _themeInfos) {
        try {
          final items = await ShopService.getItemsByThema(themeInfo.themaKey);
          _shopItemsByThema[themeInfo.themaKey] = items;
        } catch (e) {
          debugPrint('Error loading items for ${themeInfo.themaKey}: $e');
          _shopItemsByThema[themeInfo.themaKey] = [];
        }
      }

      // ⬇️ 내 구매 목록 로드
      final purchases = await ShopService.getUserPurchases();
      _purchased
        ..clear()
        ..addAll(purchases.map((p) => p.itemId));

      // ⬇️ 전역 사용자도 최신화(선택)
      await AuthService.instance.fetchMe(silent: true);
    } catch (e) {
      debugPrint('Error loading shop data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('상점 데이터를 불러오지 못했습니다.')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<bool> _askConfirm(ShopItem item) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('구매하시겠습니까?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(item.description.isEmpty ? '설명 없음' : item.description),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Image.asset('assets/images/coin.png', width: 18, height: 18),
                      const SizedBox(width: 6),
                      Text('${item.priceGold}원'),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('구매')),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _confirmBuy(ShopItem item) async {
    if (_isBuying) return;

    final ok = await _askConfirm(item);
    if (!ok) return;

    setState(() {
      _isBuying = true;
      _buyingItemId = item.itemId;
    });

    try {
      // ⬇️ 구매: POST /api/shop/purchase { itemId }
      final result = await ShopService.purchaseItem(item.itemId);

      if (result.success) {
        // ✅ 전역 사용자 상태 즉시 패치 (코인 반영)
        if (result.remainingGold != null) {
          AuthService.instance.applyMePatch(gamePoint: result.remainingGold);
        } else {
          // 혹시 서버가 금액만 안주면 /me로 싱크
          await AuthService.instance.fetchMe(silent: true);
        }

        if (mounted) {
          setState(() {
            _purchased.add(item.itemId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('구매 완료!')),
          );
        }

        // 재로딩(목록/구매상태 동기화)
        await _loadShopData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('구매 실패: ${result.message}')),
          );
        }
      }
    } catch (e) {
      debugPrint('purchase error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('구매 처리 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBuying = false;
          _buyingItemId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedThemeInfo = _themeInfos[_selectedThemeIndex];
    final selectedThemeItems =
        _shopItemsByThema[selectedThemeInfo.themaKey] ?? const <ShopItem>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('꾸미기 상점'),
        backgroundColor: green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShopData,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),

                // ✅ 상단 HUD: 전역 사용자 구독
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Image.asset('assets/images/coin.png', width: 20, height: 20),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<AuthUser?>(
                        valueListenable: AuthService.instance.currentUser,
                        builder: (_, u, __) => AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: Text(
                            '${u?.gamePoint ?? 0}',
                            key: ValueKey(u?.gamePoint ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // 현재 테마 태그
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selectedThemeInfo.bannerColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            Text(selectedThemeInfo.emoji, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              selectedThemeInfo.name,
                              style: TextStyle(
                                color: selectedThemeInfo.bannerColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 테마 선택 가로 카드
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _themeInfos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final themeInfo = _themeInfos[i];
                      final selected = i == _selectedThemeIndex;
                      final itemCount = _shopItemsByThema[themeInfo.themaKey]?.length ?? 0;

                      return _ThemeCard(
                        themeInfo: themeInfo,
                        selected: selected,
                        itemCount: itemCount,
                        onTap: () async {
                          setState(() => _selectedThemeIndex = i);
                          await Future.delayed(const Duration(milliseconds: 120));
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 14),
                Divider(thickness: 2, color: Colors.grey.shade500, height: 1),
                const SizedBox(height: 14),

                // 섹션 타이틀
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        '아이템 (${selectedThemeItems.length}개)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Spacer(),
                      Text(
                        selectedThemeInfo.name,
                        style: TextStyle(
                          color: selectedThemeInfo.bannerColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // 본문(그리드)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: _ThemeGridSection(
                      key: ValueKey('${_selectedThemeIndex}_${selectedThemeItems.length}'),
                      isEmpty: selectedThemeItems.isEmpty,
                      items: selectedThemeItems,
                      accent: selectedThemeInfo.bannerColor,
                      priceColor: olive,
                      purchased: _purchased,
                      isBuying: _isBuying,
                      buyingItemId: _buyingItemId,
                      onBuy: _confirmBuy,
                      onRefresh: _loadShopData,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/* ================== 그리드 섹션 ================== */
class _ThemeGridSection extends StatelessWidget {
  const _ThemeGridSection({
    super.key,
    required this.isEmpty,
    required this.items,
    required this.accent,
    required this.priceColor,
    required this.purchased,
    required this.isBuying,
    required this.buyingItemId,
    required this.onBuy,
    required this.onRefresh,
  });

  final bool isEmpty;
  final List<ShopItem> items;
  final Color accent;
  final Color priceColor;
  final Set<int> purchased;
  final bool isBuying;
  final int? buyingItemId;
  final Future<void> Function(ShopItem) onBuy;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      displacement: 36,
      child: isEmpty
          ? _GridSkeleton(accent: accent)
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 200,
                ),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final isPurchased = purchased.contains(item.itemId);
                  final buying = isBuying && buyingItemId == item.itemId;

                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 220),
                    tween: Tween(begin: 0, end: 1),
                    curve: Curves.easeOut,
                    builder: (context, t, child) => Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 8),
                        child: child,
                      ),
                    ),
                    child: Stack(
                      children: [
                        _ItemCard(
                          item: item,
                          accent: accent,
                          priceColor: priceColor,
                          purchased: isPurchased,
                          onRequestBuy: isPurchased || buying ? null : () => onBuy(item),
                        ),
                        if (buying)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(strokeWidth: 3),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

/* ================== 테마 카드 ================== */
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.themeInfo,
    required this.selected,
    required this.itemCount,
    required this.onTap,
  });

  final ThemeInfo themeInfo;
  final bool selected;
  final int itemCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: selected ? 6 : 2,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? themeInfo.bannerColor : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: themeInfo.bannerColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(themeInfo.emoji, style: const TextStyle(fontSize: 30))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      themeInfo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$itemCount개 아이템',
                      style: TextStyle(
                        color: themeInfo.bannerColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      themeInfo.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================== 아이템 카드 ================== */
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.accent,
    required this.purchased,
    required this.onRequestBuy,
    required this.priceColor,
  });

  final ShopItem item;
  final Color accent;
  final bool purchased;
  final VoidCallback? onRequestBuy;
  final Color priceColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: purchased ? null : onRequestBuy,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      height: 100,
                      width: double.infinity,
                      color: accent.withOpacity(0.08),
                      child: item.url.isNotEmpty
                          ? Image.network(
                              ShopService.imageUrl(item.url),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(child: Text('이미지 오류')),
                            )
                          : const Center(child: Text('📦', style: TextStyle(fontSize: 40))),
                    ),
                    if (purchased)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: Colors.black.withOpacity(0.35),
                            child: const Center(child: _PurchasedBadge()),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.itemName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Image.asset('assets/images/coin.png', width: 16, height: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${item.priceGold}원',
                    style: TextStyle(color: priceColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PurchasedBadge extends StatelessWidget {
  const _PurchasedBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 18),
          SizedBox(width: 6),
          Text('구매완료', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/* ================== 스켈레톤 ================== */
class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: GridView.builder(
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 200,
        ),
        itemBuilder: (context, i) => _SkeletonCard(accent: accent),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({required this.accent});
  final Color accent;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final hilite = Colors.grey.shade100;

    return Material(
      elevation: 3,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnimatedBuilder(
                animation: _a,
                builder: (_, __) {
                  final t = _a.value;
                  final color = Color.lerp(base, hilite, (t * 2) % 1)!;
                  return Container(
                    height: 100,
                    width: double.infinity,
                    color: color,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _line(base, width: double.infinity, height: 12),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    color: base, borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                _line(base, width: 60, height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(Color color, {required double width, required double height}) {
    return Container(
      width: width, height: height,
      decoration: BoxDecoration(
        color: color, borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/* ================== 도메인 객체 ================== */
class ThemeInfo {
  final String name;
  final String themaKey;
  final String description;
  final Color bannerColor;
  final String emoji;

  ThemeInfo({
    required this.name,
    required this.themaKey,
    required this.description,
    required this.bannerColor,
    required this.emoji,
  });
}
