import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';   

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../models/calendar_models.dart';
import '../services/calendar_service.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // 테마 색
  static const Color green = Color(0xFF8FBC8F);
  static const Color olive = Color(0xFF6B8E23);

  /// 현재 보고 있는 월의 1일 (그리드 생성용 기준)
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  /// 날짜별 이미지(Base64) 맵. key: yyyy-MM-dd
  /// - 현재 월의 데이터만 유지(월 이동 시 재로딩)
  final Map<String, String> _imagesByDay = {};

  bool _busy = false; // 네트워크 진행 표시용

  @override
  void initState() {
    super.initState();
    _loadMonthImages(_currentMonth); // 첫 진입 시 현재 월 데이터 로딩
  }

  /* ───────────── Formatting / Utils ───────────── */

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /* ───────────── Persistence (SharedPreferences) ───────────── */

  Future<void> _loadMonthImages(DateTime month) async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    final prefix =
        '${month.year}-${month.month.toString().padLeft(2, '0')}-';

    final next = <String, String>{};
    for (final k in keys) {
      if (k.startsWith('dayimg_')) {
        final dateKey = k.replaceFirst('dayimg_', '');
        if (dateKey.startsWith(prefix)) {
          final b64 = prefs.getString(k);
          if (b64 != null) next[dateKey] = b64;
        }
      }
    }
    setState(() {
      _imagesByDay
        ..clear()
        ..addAll(next);
    });
  }

  /* ───────────── Month navigation ───────────── */

  Future<void> _changeMonth(int delta) async {
    final m = DateTime(_currentMonth.year, _currentMonth.month + delta);
    setState(() => _currentMonth = DateTime(m.year, m.month));
    await _loadMonthImages(_currentMonth);
  }

  Future<void> _pickMonthByDialog() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked == null) return;
    final nextMonth = DateTime(picked.year, picked.month);
    setState(() => _currentMonth = nextMonth);
    await _loadMonthImages(_currentMonth);
  }

  /* ───────────── Image pick & save + 서버 메타 업로드 ───────────── */

  String _guessContentType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.heic') || p.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  String _basename(String path) {
    // 간단 basename (path 패키지 없이)
    final i1 = path.lastIndexOf('/');
    final i2 = path.lastIndexOf('\\');
    final idx = i1 > i2 ? i1 : i2;
    return (idx >= 0) ? path.substring(idx + 1) : path;
  }

  Future<ui.Image?> _decodeForSize(List<int> bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

Future<void> _uploadMetaToServer({
  required DateTime day,
  required XFile picked,
  required List<int> bytes,
}) async {
  try {
    setState(() => _busy = true);

    // 크기/메타 추출
    final img = await _decodeForSize(bytes);
    final width = img?.width;
    final height = img?.height;

    // ⬇︎ 체크섬 계산 (멱등/중복 업로드 방지)
    final checksum = crypto.sha256.convert(bytes).toString();

    final filePath = picked.path;
    final contentType = _guessContentType(filePath);
    final fileName = _basename(filePath);
    final fileSize = bytes.length;

    final meta = CalendarPhotoMeta(
      takenAt: DateTime.now(),
      filePath: filePath,
      fileName: fileName,
      contentType: contentType,
      fileSize: fileSize,
      width: width,
      height: height,
      checksumSha256: checksum, // ⬅︎ 추가
      // tagsJson/exifJson 필요시 세팅
    );

    final resp = await CalendarService.instance.uploadPhotoMeta(meta);
    if (!mounted) return;

    // 서버가 주는 day_key 우선 사용 (없으면 로컬 day로)
    final dayKey = (resp is dynamic) // 모델 최신이면 resp.dayKey 사용
        ? (resp.dayKey ?? resp.dayKey ?? _fmt(day))
        : _fmt(day);

    setState(() {
      _imagesByDay[dayKey] = base64Encode(bytes);
    });

    // 퀘스트 완료 알림 (멱등)
    if (resp.photoQuestCompleted == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 업로드 완료! (퀘스트 완료) — $dayKey 🎉')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('사진 등록 완료 — $dayKey')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('업로드 오류: $e')),
    );
  } finally {
    if (mounted) setState(() => _busy = false);
  }
}



  /// 주어진 날짜에 대해 카메라/갤러리에서 선택한 이미지를 저장 + 서버 메타 업로드
  Future<void> _pickImageForDate(
    DateTime day, {
    required ImageSource source,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final b64 = base64Encode(bytes);
    final key = 'dayimg_${_fmt(day)}';

    // 1) 로컬 프리뷰 저장 (기존 UX 유지)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, b64);
    setState(() {
      _imagesByDay[_fmt(day)] = b64;
    });

    // 2) 서버 메타 업로드(퀘스트 보상 트리거)
    await _uploadMetaToServer(day: day, picked: picked, bytes: bytes);
  }

  /* ───────────── Attendance (출석 체크) ───────────── */

  Future<void> _checkIn() async {
    try {
      setState(() => _busy = true);
      final r = await CalendarService.instance.checkIn(
        source: 'calendar',
        memo: '캘린더 출석',
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.firstCheckToday
                ? '출석 완료! (오늘 첫 체크)  포인트:${r.gamePoint} / EXP:${r.gameExp}'
                : '이미 출석 처리됨  포인트:${r.gamePoint} / EXP:${r.gameExp}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('출석 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /* ───────────── Tap handlers ───────────── */

  void _onTapDate(DateTime day) async {
    final key = _fmt(day);
    final hasImage = _imagesByDay.containsKey(key);
    final today = DateTime.now();

    if (!_isSameDay(day, today) && !hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('오늘만 사진을 등록할 수 있어요.'),
          duration: Duration(milliseconds: 700),
        ),
      );
      return;
    }

    if (hasImage) {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.fullscreen),
                title: const Text('크게 보기'),
                onTap: () {
                  Navigator.pop(context);
                  _showFullImage(day);
                },
              ),
              if (_isSameDay(day, today))
                ListTile(
                  leading: const Icon(Icons.change_circle_outlined),
                  title: const Text('사진 바꾸기'),
                  onTap: () {
                    Navigator.pop(context);
                    _onTapChange(day);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('삭제', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteConfirm(day);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
      return;
    }

    // 오늘 + 아직 사진 없음
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('카메라로 찍기'),
              onTap: () {
                Navigator.pop(context);
                _pickImageForDate(day, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImageForDate(day, source: ImageSource.gallery);
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  void _onTapChange(DateTime day) {
    if (!_isSameDay(day, DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('오늘만 사진을 변경할 수 있어요.'),
          duration: Duration(milliseconds: 700),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('카메라로 다시 찍기'),
              onTap: () {
                Navigator.pop(context);
                _pickImageForDate(day, source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: const Text('갤러리에서 다시 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImageForDate(day, source: ImageSource.gallery);
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteConfirm(DateTime day) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('사진 삭제'),
        content: Text('${_fmt(day)} 사진을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok == true) {
      final key = 'dayimg_${_fmt(day)}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      setState(() {
        _imagesByDay.remove(_fmt(day));
      });
      // 서버에 소프트삭제 API가 생기면 여기서도 호출하면 됨.
    }
  }

  void _showFullImage(DateTime day) {
    final b64 = _imagesByDay[_fmt(day)];
    if (b64 == null) return;
    final bytes = base64Decode(b64);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  /* ───────────── Grid helpers ───────────── */

  List<DateTime?> _buildCalendarDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final firstWeekday = first.weekday; // 1(월) ~ 7(일)
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    final leadingEmpty = (firstWeekday + 6) % 7;

    final totalCells = leadingEmpty + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final cells = rows * 7;

    final List<DateTime?> out = List.filled(cells, null);
    for (int d = 0; d < daysInMonth; d++) {
      out[leadingEmpty + d] = DateTime(month.year, month.month, d + 1);
    }
    return out;
  }

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final now = DateTime.now();
    return _isSameDay(d, now);
  }

  /* ───────────── UI ───────────── */

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays(_currentMonth);
    final monthLabel = '${_currentMonth.year}년 ${_currentMonth.month}월';
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        backgroundColor: green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: '출석 체크',
            onPressed: _busy ? null : _checkIn,
            icon: const Icon(Icons.how_to_reg_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // 상단: 월 전/후 이동 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _busy ? null : () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Center(
                          child: InkWell(
                            onTap: _busy ? null : _pickMonthByDialog,
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_month_outlined, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    monthLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _busy ? null : () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // 요일 헤더(월~일)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: const [
                      _Weekday('월'),
                      _Weekday('화'),
                      _Weekday('수'),
                      _Weekday('목'),
                      _Weekday('금'),
                      _Weekday('토'),
                      _Weekday('일'),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // 달력 그리드
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: days.length,
                      itemBuilder: (_, i) {
                        final day = days[i];
                        if (day == null) {
                          return const SizedBox.shrink();
                        }
                        final key = _fmt(day);
                        final b64 = _imagesByDay[key];
                        final hasImg = b64 != null;
                        final isTodayCell = _isSameDay(day, today);
                        final shouldDim = !isTodayCell && !hasImg;

                        return InkWell(
                          onTap: _busy ? null : () => _onTapDate(day),
                          onLongPress: _busy
                              ? null
                              : (hasImg ? () => _deleteConfirm(day) : null),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isToday(day) ? olive : Colors.grey.shade300,
                                width: _isToday(day) ? 2 : 1,
                              ),
                              color: Colors.white,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              children: [
                                if (hasImg)
                                  Positioned.fill(
                                    child: Image.memory(
                                      base64Decode(b64),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Positioned(
                                  top: 4,
                                  left: 6,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hasImg
                                          ? Colors.black.withValues(alpha: 0.45)
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${day.day}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: hasImg
                                            ? Colors.white
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!hasImg)
                                  Center(
                                    child: Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 22,
                                      color: shouldDim
                                          ? Colors.grey.shade300
                                          : Colors.grey,
                                    ),
                                  ),
                                if (shouldDim)
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: Container(
                                        color: Colors.white.withValues(alpha: 0.55),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_busy)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.08),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _Weekday extends StatelessWidget {
  const _Weekday(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
