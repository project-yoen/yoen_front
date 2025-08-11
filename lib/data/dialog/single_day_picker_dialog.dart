// single_day_picker_dialog.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// TableCalendar 기반 단일 날짜 선택 다이얼로그.
/// - 토요일: 파랑, 일요일: 빨강 (활성일 때만 색 적용)
/// - 범위 밖 날짜: 회색 비활성
/// - 날짜 탭 시 즉시 pop(DateTime) 반환
class SingleDayPickerDialog extends StatefulWidget {
  const SingleDayPickerDialog({
    super.key,
    required this.minDate,
    required this.maxDate,
    required this.initialDate,
    this.title = '날짜 선택',
    this.cancelText = '취소',
  });

  final DateTime minDate; // 선택 가능 최소일
  final DateTime maxDate; // 선택 가능 최대일
  final DateTime initialDate; // 초기 포커스/선택일
  final String title;
  final String cancelText;

  @override
  State<SingleDayPickerDialog> createState() => _SingleDayPickerDialogState();
}

class _SingleDayPickerDialogState extends State<SingleDayPickerDialog> {
  late final DateTime _min; // dateOnly
  late final DateTime _max; // dateOnly
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    // ✅ 모두 자정 기준으로 정규화 (시간 섞임 방지)
    _min = DateUtils.dateOnly(widget.minDate);
    _max = DateUtils.dateOnly(widget.maxDate);
    final initial = _clamp(DateUtils.dateOnly(widget.initialDate), _min, _max);
    _focusedDay = initial;
    _selectedDay = initial;
  }

  DateTime _clamp(DateTime d, DateTime min, DateTime max) {
    if (d.isBefore(min)) return min;
    if (d.isAfter(max)) return max;
    return d;
  }

  bool _inRange(DateTime d) => !d.isBefore(_min) && !d.isAfter(_max);

  bool _isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  String _dowKo(int weekday) {
    // 1~7: Mon..Sun
    const names = ['월', '화', '수', '목', '금', '토', '일'];
    return names[(weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SafeArea(
        minimum: const EdgeInsets.all(12),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              TableCalendar(
                // 범위는 dateOnly로 전달
                firstDay: _min,
                lastDay: _max,
                focusedDay: _focusedDay,
                calendarFormat: _format,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                onFormatChanged: (f) => setState(() => _format = f),
                onPageChanged: (fd) => _focusedDay = DateUtils.dateOnly(fd),

                // ✅ 범위 밖 날짜 비활성
                enabledDayPredicate: (day) => _inRange(DateUtils.dateOnly(day)),

                selectedDayPredicate: (day) =>
                    _selectedDay != null && isSameDay(_selectedDay, day),

                onDaySelected: (selectedDay, focusedDay) {
                  final d = DateUtils.dateOnly(selectedDay);
                  if (!_inRange(d)) return;
                  setState(() {
                    _selectedDay = d;
                    _focusedDay = d;
                  });
                  Navigator.pop<DateTime>(context, d);
                },

                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),

                // 요일 헤더/셀 색상 커스터마이즈
                calendarBuilders: CalendarBuilders(
                  // 요일 헤더 (월~일)
                  dowBuilder: (context, day) {
                    final isSat = day.weekday == DateTime.saturday;
                    final isSun = day.weekday == DateTime.sunday;
                    final color = isSat
                        ? Colors.blue
                        : (isSun ? Colors.red : null);
                    return Center(
                      child: Text(
                        _dowKo(day.weekday),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w600,
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

                    // 비활성: 회색
                    if (!enabled) {
                      return Center(
                        child: Text(
                          '${d.day}',
                          style: TextStyle(color: Colors.grey.withOpacity(0.6)),
                        ),
                      );
                    }

                    // 활성 + 주말: 파/빨
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

                    // 평일: 기본 렌더
                    return null;
                  },

                  // 다른 달 날짜 (outside)
                  outsideBuilder: (context, day, focused) {
                    final d = DateUtils.dateOnly(day);
                    final enabled = _inRange(d);
                    final isSat = d.weekday == DateTime.saturday;
                    final isSun = d.weekday == DateTime.sunday;

                    // 비활성 outside
                    if (!enabled) {
                      return Center(
                        child: Text(
                          '${d.day}',
                          style: TextStyle(color: Colors.grey.withOpacity(0.4)),
                        ),
                      );
                    }

                    // 활성 outside + 주말
                    if (isSat || isSun) {
                      final base = isSat ? Colors.blue : Colors.red;
                      return Center(
                        child: Text(
                          '${d.day}',
                          style: TextStyle(color: base.withOpacity(0.5)),
                        ),
                      );
                    }

                    // 그 외 outside는 기본
                    return null;
                  },
                ),

                calendarStyle: CalendarStyle(
                  // 오늘은 테두리만
                  todayDecoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.4),
                    ),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(color: Colors.black),
                  // 선택일 배경
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  // 비활성 텍스트(안전망)
                  disabledTextStyle: TextStyle(
                    color: Colors.grey.withOpacity(0.6),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(widget.cancelText),
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
