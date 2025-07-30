import 'package:flutter_riverpod/flutter_riverpod.dart';

class DateNotifier extends StateNotifier<DateTime?> {
  DateNotifier() : super(null);

  void setDate(DateTime date) {
    state = date;
  }

  void nextDay(DateTime endDate) {
    if (state != null && !state!.isAtSameMomentAs(endDate)) {
      state = state!.add(const Duration(days: 1));
    }
  }

  void previousDay(DateTime startDate) {
    if (state != null && !state!.isAtSameMomentAs(startDate)) {
      state = state!.subtract(const Duration(days: 1));
    }
  }
}

final dateNotifierProvider = StateNotifierProvider<DateNotifier, DateTime?>((ref) {
  return DateNotifier();
});
