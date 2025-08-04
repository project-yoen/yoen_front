import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class TravelDatePickerDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const TravelDatePickerDialog({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<TravelDatePickerDialog> createState() => _TravelDatePickerDialogState();
}

class _TravelDatePickerDialogState extends State<TravelDatePickerDialog> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOn; // Can be toggled on or off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();

    // 기존에 선택한 범위가 있으면 그 시작 날짜를 기준으로 캘린더를 열도록
    _rangeStart = widget.initialStartDate;
    _rangeEnd = widget.initialEndDate;

    if (_rangeStart != null) {
      _focusedDay = _rangeStart!;
    } else {
      _focusedDay = DateTime.now();
    }

    _selectedDay = _focusedDay;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null; // Important to clean those
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;

      // 범위가 이미 선택되어 있으면 → 초기화하고 다시 시작
      if (_rangeStart != null &&
          _rangeEnd != null &&
          _rangeStart != _rangeEnd) {
        _rangeStart = focusedDay;
        _rangeEnd = focusedDay;
      }
      // 처음 선택하거나 아직 1개만 선택된 상태면 → 범위 확장
      else if (_rangeStart == null && _rangeEnd == null) {
        _rangeStart = focusedDay;
        _rangeEnd = focusedDay;
      } else if (_rangeStart != null && _rangeEnd == _rangeStart) {
        if (focusedDay.isBefore(_rangeStart!)) {
          _rangeStart = focusedDay;
        } else {
          _rangeEnd = focusedDay;
        }
      }
      // 기타 이상한 경우에도 안전하게 초기화
      else {
        _rangeStart = focusedDay;
        _rangeEnd = focusedDay;
      }

      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '여행 날짜 입력',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            TableCalendar(
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2050, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              onDayLongPressed: (day, focusedDay) {
                _onRangeSelected(null, null, day);
              },
              calendarFormat: _calendarFormat,
              rangeSelectionMode: _rangeSelectionMode,
              onDaySelected: _onDaySelected,
              onRangeSelected: _onRangeSelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                prioritizedBuilder: (context, day, focusedDay) {
                  final isSelected = isSameDay(_selectedDay, day);
                  final isRangeStart = isSameDay(_rangeStart, day);
                  final isRangeEnd = isSameDay(_rangeEnd, day);

                  if (isSelected || isRangeStart || isRangeEnd) {
                    return null;
                  }
                  
                  final bool isOutside = day.month != _focusedDay.month;

                  if (day.weekday == DateTime.saturday) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                            color: isOutside
                                ? Colors.blue.withOpacity(0.5)
                                : Colors.blue),
                      ),
                    );
                  }
                  if (day.weekday == DateTime.sunday) {
                    return Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                            color: isOutside
                                ? Colors.red.withOpacity(0.5)
                                : Colors.red),
                      ),
                    );
                  }
                  return null;
                },
              ),
              calendarStyle: CalendarStyle(
                todayTextStyle: const TextStyle(color: Colors.black),
                todayDecoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                rangeStartDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                rangeHighlightColor: Colors.blue.withOpacity(0.2),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 취소
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop({'start': _rangeStart, 'end': _rangeEnd});
                  },
                  child: const Text('선택'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
