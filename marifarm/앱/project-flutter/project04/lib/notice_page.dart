// lib/notice_page.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';

/// ----------------------------------------------------------------------------
/// NoticePage (UI 전용, 심플 버전)
/// - DB 연동 시 [fetchNotices], [onRefresh]만 연결하면 됨
/// ----------------------------------------------------------------------------
class NoticePage extends StatefulWidget {
  const NoticePage({
    super.key,
    this.fetchNotices,
    this.onRefresh,
  });

  /// 페이지네이션 로더 (1부터 시작). 전달하지 않으면 데모 데이터 사용.
  final Future<List<Notice>> Function(int page, String query)? fetchNotices;

  /// 외부 새로고침 훅(선택)
  final Future<void> Function()? onRefresh;

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  // 상태
  final List<Notice> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 1;
  String _query = '';
  String? _error;

  // 검색 디바운스
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ───────────────── 데이터 로딩 ─────────────────
  Future<List<Notice>> _fetch(int page, String query) async {
    if (widget.fetchNotices != null) {
      return await widget.fetchNotices!(page, query);
    }

    // ▼ 데모 데이터 (실서버 연동 시 제거)
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();

    // 예시용 아주 작은 base64 이미지(1x1 회색 픽셀)
    const samplePixelBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABJ4kq0QAAAABJRU5ErkJggg==';

    final all = <Notice>[
      Notice(
        id: '1',
        title: '8월 출석 이벤트 안내',
        content: '매일 접속 시 코인과 XP 보상이 지급됩니다!',
        createdAt: now.subtract(const Duration(hours: 5)),
        imageBase64: samplePixelBase64,
      ),
      Notice(
        id: '2',
        title: '신규 테마 업데이트',
        content: '그린 팜/우드 코지 테마가 추가되었습니다. 상점에서 확인해 보세요!',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
      ),
      Notice(
        id: '3',
        title: '버그 수정 내역',
        content: '사진 업로드 안정성 향상 및 캘린더 UI 수정을 반영했습니다.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];

    // 검색
    final filtered = all
        .where((n) =>
            n.title.toLowerCase().contains(query.toLowerCase()) ||
            n.content.toLowerCase().contains(query.toLowerCase()))
        .toList();

    // 간단 페이지네이션(2개씩)
    const pageSize = 2;
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }

  Future<void> _loadFirst() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _items.clear();
      _page = 1;
      _hasMore = true;
    });
    try {
      final data = await _fetch(_page, _query);
      setState(() {
        _items.addAll(data);
        _hasMore = data.isNotEmpty;
      });
    } catch (e) {
      setState(() => _error = '공지사항을 불러오지 못했습니다.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final next = _page + 1;
      final data = await _fetch(next, _query);
      setState(() {
        _page = next;
        _items.addAll(data);
        if (data.isEmpty) _hasMore = false;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ───────────────── 검색 디바운스 ─────────────────
  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _query = text.trim());
      _loadFirst();
    });
  }

  // ───────────────── UI ─────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공지사항')),
      body: RefreshIndicator(
        onRefresh: () async {
          if (widget.onRefresh != null) await widget.onRefresh!();
          await _loadFirst();
        },
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: '제목/내용 검색',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, __) => const _Skeleton(),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemCount: 6,
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          _StateBox(
            icon: Icons.error_outline,
            title: '불러오기 실패',
            message: _error!,
            actionText: '다시 시도',
            onPressed: _loadFirst,
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          _StateBox(
            icon: Icons.inbox_outlined,
            title: '공지사항이 없어요',
            message: '새로운 공지가 등록되면 이곳에 표시됩니다.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 4),
        ..._items.map(_tile),
        if (_hasMore) _More(isLoading: _isLoading, onTap: _loadMore),
        const SizedBox(height: 12),
      ],
    );
  }

  // 목록 타일(심플): 제목 / 요약 / 날짜
  Widget _tile(Notice n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDetail(n),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목
                Text(
                  n.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 한 줄 요약
                Text(
                  n.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                // 날짜만
                Text(
                  _fmtDate(n.createdAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 상세 시트(이미지 있으면 표시)
  void _showDetail(Notice n) {
    final bytes = n.imageBase64 != null ? base64Decode(n.imageBase64!) : null;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 6),
              Text(
                n.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                _fmtDate(n.createdAt),
                style: TextStyle(color: Colors.grey.shade600),
              ),
              if (bytes != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Text(n.content, style: const TextStyle(fontSize: 15, height: 1.5)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final now = DateTime.now();
    final isToday = d.year == now.year && d.month == now.month && d.day == now.day;
    if (isToday) {
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return '오늘 $hh:$mm';
    }
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }
}

/* ======================= Model & Small Widgets ======================= */

/// 공지 모델(심플)
/// - 팀/작성자/핀, 읽음여부 전부 제거
/// - 필요 시 서버 URL을 쓰려면 imageUrl 필드를 추가해서 Image.network 사용
class Notice {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? imageBase64;

  Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.imageBase64,
  });
}

/// 상태 박스(빈/에러)
class _StateBox extends StatelessWidget {
  const _StateBox({
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            if (actionText != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onPressed, child: Text(actionText!)),
            ]
          ],
        ),
      ),
    );
  }
}

/// 로딩 스켈레톤
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 16),
        bar(28, 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bar(180, 14),
              const SizedBox(height: 8),
              bar(double.infinity, 12),
              const SizedBox(height: 6),
              bar(120, 10),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

/// 더보기 버튼
class _More extends StatelessWidget {
  const _More({required this.isLoading, required this.onTap});
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onTap,
        icon: isLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.expand_more),
        label: Text(isLoading ? '불러오는 중...' : '더 보기'),
      ),
    );
  }
}
