// design_page.dart
import 'package:flutter/material.dart';
import 'models/decor_models.dart';
import 'services/decor_service.dart';
import 'services/shop_service.dart'; // imageUrl 사용

class DesignPage extends StatefulWidget {
  const DesignPage({super.key});

  @override
  State<DesignPage> createState() => _DesignPageState();
}

/// 장착 슬롯(= DB thema와 동일한 한글 키)
enum FurnitureSlot { background, wall, floor }
String slotLabel(FurnitureSlot s) {
  switch (s) {
    case FurnitureSlot.background:
      return '여름테마';
    case FurnitureSlot.wall:
      return '벽';
    case FurnitureSlot.floor:
      return '바닥';
  }
}

class _DesignPageState extends State<DesignPage> {
  static const Color green = Color(0xFF8FBC8F);
  static const Color olive = Color(0xFF6B8E23);

  FurnitureSlot _selectedSlot = FurnitureSlot.background;

  /// 서버 상태
  Map<String, List<EquippedItem>> _equippedBySlot = {};
  List<DecorInventoryItem> _inventoryForSlot = [];

  bool _isLoading = true;
  bool _isMutating = false;
  int? _mutatingItemId;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() => _isLoading = true);
    final slot = slotLabel(_selectedSlot);
    final snap = await DecorService.refreshForSlot(slot);
    if (!mounted) return;
    setState(() {
      _equippedBySlot = snap.equippedBySlot;
      _inventoryForSlot = snap.inventoryForSlot;
      _isLoading = false;
    });
  }

  Future<void> _onChangeSlot(FurnitureSlot next) async {
    if (_selectedSlot == next) return;
    setState(() {
      _selectedSlot = next;
      _isLoading = true;
    });
    final slot = slotLabel(next);
    final snap = await DecorService.refreshForSlot(slot);
    if (!mounted) return;
    setState(() {
      _equippedBySlot = snap.equippedBySlot;
      _inventoryForSlot = snap.inventoryForSlot;
      _isLoading = false;
    });
  }

  bool _isEquipped(DecorInventoryItem it) {
    // 모델 필드에 이미 equipped가 있으므로 우선 사용
    if (it.equipped) return true;
    // 안전 장치: equipped 버킷에도 있는지 확인
    final list = _equippedBySlot[it.slot] ?? const [];
    return list.any((e) => e.itemId == it.itemId);
  }

  Future<void> _onTapItem(DecorInventoryItem item) async {
    if (_isMutating) return;
    final slot = item.slot; // '배경' | '벽' | '바닥'
    final isEquipped = _isEquipped(item);

    if (isEquipped) {
      final ok = await _confirm(
        title: '해제하시겠습니까?',
        content: '"${item.itemName}"을(를) 해제합니다.',
        positiveText: '해제',
      );
      if (ok != true) return;

      setState(() {
        _isMutating = true;
        _mutatingItemId = item.itemId;
      });

      final okApi = await DecorService.unequip(slot, itemId: item.itemId);
      if (!mounted) return;
      if (okApi) {
        await _refreshAll();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해제 완료')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해제 실패')),
        );
      }
      setState(() {
        _isMutating = false;
        _mutatingItemId = null;
      });
      return;
    }

    // 장착/교체
    final currentNames = _currentEquippedNamesFor(slot);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(currentNames.isEmpty ? '장착하시겠습니까?' : '$slot 교체'),
        content: currentNames.isEmpty
            ? Text('"${item.itemName}"을(를) 장착합니다.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _compareRow(label: '현재', name: currentNames.join(', ')),
                  const SizedBox(height: 8),
                  _compareRow(label: '선택', name: item.itemName),
                ],
              ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('확인')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() {
      _isMutating = true;
      _mutatingItemId = item.itemId;
    });

    final okApi = await DecorService.equip(item.itemId, slot: slot);
    if (!mounted) return;
    if (okApi) {
      await _refreshAll();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장착 완료')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('장착 실패')),
      );
    }
    setState(() {
      _isMutating = false;
      _mutatingItemId = null;
    });
  }

  List<String> _currentEquippedNamesFor(String slot) {
    final ids = (_equippedBySlot[slot] ?? const []).map((e) => e.itemId).toSet();
    final names = _inventoryForSlot
        .where((it) => ids.contains(it.itemId))
        .map((it) => it.itemName)
        .toList();
    return names;
  }

  Future<bool?> _confirm({
    required String title,
    required String content,
    required String positiveText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(positiveText)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slotKo = slotLabel(_selectedSlot);

    return Scaffold(
      appBar: AppBar(
        title: const Text('꾸미기'),
        backgroundColor: green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll, tooltip: '새로고침'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshAll,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ⛔ 미리보기 제거됨
                          const Text('슬롯 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          _SlotSelector(selected: _selectedSlot, onChanged: _onChangeSlot),
                          const SizedBox(height: 14),
                          Divider(thickness: 2, color: Colors.grey.shade400, height: 1),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                '$slotKo 보유 아이템',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Spacer(),
                              Text(
                                '총 ${_inventoryForSlot.length}개',
                                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  _inventoryForSlot.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: Text('해당 슬롯의 보유 아이템이 없습니다.')),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final it = _inventoryForSlot[i];
                                final equipped = _isEquipped(it);
                                final mutating = _isMutating && _mutatingItemId == it.itemId;
                                return Stack(
                                  children: [
                                    _OwnedItemCard(
                                      item: it,
                                      accent: green,
                                      priceColor: olive,
                                      isEquipped: equipped,
                                      onTap: mutating ? null : () => _onTapItem(it),
                                    ),
                                    if (mutating)
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
                                );
                              },
                              childCount: _inventoryForSlot.length,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              mainAxisExtent: 200,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _compareRow({required String label, required String name}) {
    return Row(
      children: [
        SizedBox(width: 40, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

/* ================== 슬롯 선택 위젯 ================== */
class _SlotSelector extends StatelessWidget {
  const _SlotSelector({required this.selected, required this.onChanged});
  final FurnitureSlot selected;
  final ValueChanged<FurnitureSlot> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final slot = FurnitureSlot.values[i];
          final label = slotLabel(slot);
          final isSel = slot == selected;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onChanged(slot),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF8FBC8F).withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSel ? const Color(0xFF8FBC8F) : Colors.grey.shade300,
                  width: isSel ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    slot == FurnitureSlot.background
                        ? Icons.landscape
                        : slot == FurnitureSlot.wall
                            ? Icons.wallpaper
                            : Icons.texture,
                    size: 18,
                    color: isSel ? const Color(0xFF8FBC8F) : Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSel ? const Color(0xFF8FBC8F) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ================== 보유 아이템 카드 ================== */
class _OwnedItemCard extends StatelessWidget {
  const _OwnedItemCard({
    required this.item,
    required this.accent,
    required this.priceColor,
    required this.onTap,
    this.isEquipped = false,
  });

  final DecorInventoryItem item;
  final Color accent;
  final Color priceColor;
  final VoidCallback? onTap;
  final bool isEquipped;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                            : const Center(child: Text('🎨', style: TextStyle(fontSize: 40))),
                      ),
                      if (isEquipped)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.35),
                            child: const Center(child: _EquippedBadge()),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(item.slot, style: const TextStyle(fontSize: 11)),
                    ),
                    const Spacer(),
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
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquippedBadge extends StatelessWidget {
  const _EquippedBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: const Text('장착중', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
