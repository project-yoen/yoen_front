// universal_date_picker_dialog.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

enum _PickerMode { single, range }

/// TableCalendar 기반 범용 날짜 선택 다이얼로그
/// - 토요일: 파랑, 일요일: 빨강 (활성일만)
/// - 범위 밖: 비활성(회색)
/// - 단일 날짜: 탭 시 즉시 pop(DateTime)
/// - 기간 선택: range 하이라이트 + '확인'으로 {'start','end'} 반환
/// - 헤더 제목 탭: 연도 선택(YearPicker)
class UniversalDatePickerDialog extends StatefulWidget {
  // 공통
  final DateTime minDate;
  final DateTime maxDate;
  final String title;
  final String cancelText;
  final String confirmText;

  // 단일
  final DateTime? initialDate;

  // 범위
  final DateTime? initialStart;
  final DateTime? initialEnd;

  final _PickerMode _mode;

  const UniversalDatePickerDialog._({
    super.key,
    required this.minDate,
    required this.maxDate,
    required this.title,
    required this.cancelText,
    required this.confirmText,
    required _PickerMode mode,
    this.initialDate,
    this.initialStart,
    this.initialEnd,
  }) : _mode = mode;

  /// 단일 날짜 선택
  factory UniversalDatePickerDialog.single({
    Key? key,
    required DateTime minDate,
    required DateTime maxDate,
    required DateTime initialDate,
    String title = '날짜 선택',
    String cancelText = '취소',
    String confirmText = '확인',
  }) {
    return UniversalDatePickerDialog._(
      key: key,
      minDate: minDate,
      maxDate: maxDate,
      initialDate: initialDate,
      title: title,
      cancelText: cancelText,
      confirmText: confirmText,
      mode: _PickerMode.single,
    );
  }

  /// 기간 선택 (start~end)
  factory UniversalDatePickerDialog.range({
    Key? key,
    required DateTime minDate,
    required DateTime maxDate,
    DateTime? initialStart,
    DateTime? initialEnd,
    String title = '기간 선택',
    String cancelText = '취소',
    String confirmText = '선택',
  }) {
    return UniversalDatePickerDialog._(
      key: key,
      minDate: minDate,
      maxDate: maxDate,
      initialStart: initialStart,
      initialEnd: initialEnd,
      title: title,
      cancelText: cancelText,
      confirmText: confirmText,
      mode: _PickerMode.range,
    );
  }

  @override
  State<UniversalDatePickerDialog> createState() =>
      _UniversalDatePickerDialogState();
}

class _UniversalDatePickerDialogState extends State<UniversalDatePickerDialog> {
  late final DateTime _min; // dateOnly
  late final DateTime _max; // dateOnly
  CalendarFormat _format = CalendarFormat.month;

  // 공통
  late DateTime _focusedDay;

  // 단일
  DateTime? _selectedDay;

  // 범위
  RangeSelectionMode _rangeMode = RangeSelectionMode.toggledOn;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _min = DateUtils.dateOnly(widget.minDate);
    _max = DateUtils.dateOnly(widget.maxDate);

    if (widget._mode == _PickerMode.single) {
      final initial = _clamp(
        DateUtils.dateOnly(widget.initialDate!),
        _min,
        _max,
      );
      _focusedDay = initial;
      _selectedDay = initial;
    } else {
      _rangeStart = widget.initialStart != null
          ? DateUtils.dateOnly(widget.initialStart!)
          : null;
      _rangeEnd = widget.initialEnd != null
          ? DateUtils.dateOnly(widget.initialEnd!)
          : null;

      // 포커스는 start/오늘/최소일 순
      _focusedDay =
          _rangeStart ??
          (_inRange(DateUtils.dateOnly(DateTime.now()))
              ? DateUtils.dateOnly(DateTime.now())
              : _min);
    }
  }

  // 유틸
  DateTime _clamp(DateTime d, DateTime min, DateTime max) {
    if (d.isBefore(min)) return min;
    if (d.isAfter(max)) return max;
    return d;
  }

  bool _inRange(DateTime d) => !d.isBefore(_min) && !d.isAfter(_max);

  // 헤더: 연도 선택
  Future<void> _pickYear() async {
    final first = _min.year;
    final last = _max.year;

    final selectedYear = await showDialog<int>(
      context: context,
      builder: (ctx) {
        const itemExtent = 44.0;
        final count = last - first + 1;
        final initialIndex = (_focusedDay.year - first).clamp(0, count - 1);
        final controller = ScrollController(
          initialScrollOffset: initialIndex * itemExtent,
        );
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: 280,
            height: 360,
            child: Column(
              children: [
                const SizedBox(height: 12),
                const Text(
                  '연도 선택',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Scrollbar(
                    controller: controller,
                    child: ListView.builder(
                      controller: controller,
                      itemExtent: itemExtent,
                      itemCount: count,
                      itemBuilder: (_, i) {
                        final year = first + i;
                        final isSelected = year == _focusedDay.year;
                        return InkWell(
                          onTap: () => Navigator.of(ctx).pop(year),
                          child: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: isSelected
                                ? (isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.black.withOpacity(0.04))
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$year년',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('닫기'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (selectedYear != null) {
      // 선택한 연도로 이동 (월은 범위 보정)
      int month = _focusedDay.month;
      if (selectedYear == _min.year && month < _min.month) month = _min.month;
      if (selectedYear == _max.year && month > _max.month) month = _max.month;

      setState(() {
        _focusedDay = _clamp(DateTime(selectedYear, month, 1), _min, _max);
      });
    }
  }

  void _goPrevMonth() {
    final target = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    setState(() => _focusedDay = _clamp(target, _min, _max));
  }

  void _goNextMonth() {
    final target = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    setState(() => _focusedDay = _clamp(target, _min, _max));
  }

  @override
  Widget build(BuildContext context) {
    final canPrev =
        DateTime(_focusedDay.year, _focusedDay.month - 1, 1).isAfter(_min) ||
        DateTime(
          _focusedDay.year,
          _focusedDay.month - 1,
          1,
        ).isAtSameMomentAs(_min);
    final canNext =
        DateTime(_focusedDay.year, _focusedDay.month + 1, 1).isBefore(_max) ||
        DateTime(
          _focusedDay.year,
          _focusedDay.month + 1,
          1,
        ).isAtSameMomentAs(_max);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 타이틀
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),

              // 커스텀 헤더 (월 내비 + 연도 선택)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: canPrev ? _goPrevMonth : null,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: '이전 달',
                  ),
                  TextButton.icon(
                    onPressed: _pickYear,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      '${_focusedDay.year}년 ${_focusedDay.month}월',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: canNext ? _goNextMonth : null,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: '다음 달',
                  ),
                ],
              ),

              // 캘린더
              TableCalendar(
                headerVisible: false, // 내부 헤더 숨김(우리가 커스텀)
                firstDay: _min,
                lastDay: _max,
                focusedDay: _focusedDay,
                calendarFormat: _format,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                onFormatChanged: (f) => setState(() => _format = f),
                onPageChanged: (fd) => _focusedDay = DateUtils.dateOnly(fd),
                daysOfWeekHeight: 30, // 28~32 사이에서 취향에 맞게

                enabledDayPredicate: (day) => _inRange(DateUtils.dateOnly(day)),

                // 단일
                selectedDayPredicate: (day) =>
                    widget._mode == _PickerMode.single &&
                    _selectedDay != null &&
                    isSameDay(_selectedDay, day),

                onDaySelected: (selectedDay, focusedDay) {
                  final d = DateUtils.dateOnly(selectedDay);
                  if (!_inRange(d)) return;

                  if (widget._mode == _PickerMode.single) {
                    // 즉시 반환
                    Navigator.pop<DateTime>(context, d);
                    return;
                  }

                  // range 모드에서는 일단 selectedDay를 비움 (시각적 강조는 range로)
                  setState(() {
                    _selectedDay = null;
                  });
                },

                // 기간 선택 모드 핸들러
                rangeSelectionMode: widget._mode == _PickerMode.range
                    ? _rangeMode
                    : RangeSelectionMode.toggledOff,
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                onRangeSelected: widget._mode == _PickerMode.range
                    ? (start, end, fd) {
                        final s = start != null
                            ? _clamp(DateUtils.dateOnly(start), _min, _max)
                            : null;
                        final e = end != null
                            ? _clamp(DateUtils.dateOnly(end), _min, _max)
                            : null;
                        setState(() {
                          _focusedDay = DateUtils.dateOnly(fd);
                          _rangeStart = s;
                          _rangeEnd = e ?? s; // 단일도 허용
                          _rangeMode = RangeSelectionMode.toggledOn;
                        });
                      }
                    : null,

                // 요일/셀 스타일 커스터마이즈
                calendarBuilders: CalendarBuilders(
                  // 요일 헤더(월~일)
                  dowBuilder: (context, day) {
                    final names = const ['월', '화', '수', '목', '금', '토', '일'];
                    final label = names[(day.weekday - 1) % 7];
                    final isSat = day.weekday == DateTime.saturday;
                    final isSun = day.weekday == DateTime.sunday;
                    final color = isSat
                        ? Colors.blue
                        : (isSun ? Colors.red : null);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2), // ← 하단 여백
                      child: Align(
                        alignment: Alignment.bottomCenter, // ← 아래 정렬(시각적으로 안정감)
                        child: Text(
                          label,
                          // height를 살짝 키워도 좋습니다 (플랫폼별 글꼴 라인 박스 보정)
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            height: 1.1, // 선택 사항
                          ),
                        ),
                      ),
                    );
                  },

                  // 기본 날짜 셀
                  defaultBuilder: (context, day, focused) {
                    final d = DateUtils.dateOnly(day);
                    final enabled = _inRange(d);
                    final isSat = d.weekday == DateTime.saturday;
                    final isSun = d.weekday == DateTime.sunday;

                    if (!enabled) {
                      return Center(
                        child: Text(
                          '${d.day}',
                          style: TextStyle(color: Colors.grey.withOpacity(0.6)),
                        ),
                      );
                    }

                    if (isSat || isSun) {
                      final color = isSat ? Colors.blue : Colors.red;
                      final isOutside = d.month != _focusedDay.month;
                      return Center(
                        child: Text(
                          '${d.day}',
                          style: TextStyle(
                            color: isOutside ? color.withOpacity(0.5) : color,
                          ),
                        ),
                      );
                    }
                    return null; // 기본 렌더
                  },

                  // 다른 달 날짜(outside)
                  outsideBuilder: (context, day, focused) {
                    final d = DateUtils.dateOnly(day);
                    final enabled = _inRange(d);
                    final isSat = d.weekday == DateTime.saturday;
                    final isSun = d.weekday == DateTime.sunday;

                    if (!enabled) {
                      return Center(
                        child: Text(
                          '${d.day}',
                          style: TextStyle(color: Colors.grey.withOpacity(0.4)),
                        ),
                      );
                    }

                    if (isSat || isSun) {
                      final base = isSat ? Colors.blue : Colors.red;
                      return Center(
                        child: Text(
                          '${d.day}',
                          style: TextStyle(color: base.withOpacity(0.5)),
                        ),
                      );
                    }
                    return null;
                  },
                ),

                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.4),
                    ),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: Colors.black),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  // range
                  rangeStartDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  rangeHighlightColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.15),
                  disabledTextStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.6),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 하단 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(widget.cancelText),
                  ),
                  if (widget._mode == _PickerMode.range) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: (_rangeStart != null && _rangeEnd != null)
                          ? () => Navigator.pop(context, {
                              'start': _rangeStart,
                              'end': _rangeEnd,
                            })
                          : null,
                      child: Text(widget.confirmText),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
