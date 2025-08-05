import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/payment_response.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/model/timeline_item.dart';
import 'package:yoen_front/data/repository/payment_repository.dart';
import 'package:yoen_front/data/repository/record_repository.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart';

enum OverviewStatus { initial, loading, success, error }

class OverviewState {
  final OverviewStatus status;
  final List<TimelineItem> items;
  final String? errorMessage;

  OverviewState({
    this.status = OverviewStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  OverviewState copyWith({
    OverviewStatus? status,
    List<TimelineItem>? items,
    String? errorMessage,
  }) {
    return OverviewState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OverviewNotifier extends StateNotifier<OverviewState> {
  final RecordRepository _recordRepository;
  final PaymentRepository _paymentRepository;

  OverviewNotifier(this._recordRepository, this._paymentRepository)
      : super(OverviewState());

  Future<void> fetchTimeline(int travelId, DateTime date) async {
    state = state.copyWith(status: OverviewStatus.loading);
    try {
      final dateString = date.toIso8601String();
      final recordsFuture = _recordRepository.getRecords(travelId, dateString);
      final paymentsFuture =
          _paymentRepository.getPayments(travelId, dateString);

      final List<RecordResponse> records = await recordsFuture;
      final List<PaymentResponse> payments = await paymentsFuture;

      final List<TimelineItem> timelineItems = [];

      for (var record in records) {
        timelineItems.add(TimelineItem(
          type: TimelineItemType.record,
          timestamp: DateTime.parse(record.recordTime),
          data: record,
        ));
      }

      for (var payment in payments) {
        timelineItems.add(TimelineItem(
          type: TimelineItemType.payment,
          timestamp: DateTime.parse(payment.payTime),
          data: payment,
        ));
      }

      timelineItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      state =
          state.copyWith(status: OverviewStatus.success, items: timelineItems);
    } catch (e) {
      state =
          state.copyWith(status: OverviewStatus.error, errorMessage: e.toString());
    }
  }
}

final overviewNotifierProvider =
    StateNotifierProvider<OverviewNotifier, OverviewState>((ref) {
  final recordRepository = ref.watch(recordRepositoryProvider);
  final paymentRepository = ref.watch(paymentRepositoryProvider);
  return OverviewNotifier(recordRepository, paymentRepository);
});