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

  /// 마지막 조회 컨텍스트(업데이트 후 재조회나 refreshLast용)
  final int? lastTravelId;
  final DateTime? lastDate;

  OverviewState({
    this.status = OverviewStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.lastTravelId,
    this.lastDate,
  });

  OverviewState copyWith({
    OverviewStatus? status,
    List<TimelineItem>? items,
    String? errorMessage,
    int? lastTravelId,
    DateTime? lastDate,
  }) {
    return OverviewState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      lastTravelId: lastTravelId ?? this.lastTravelId,
      lastDate: lastDate ?? this.lastDate,
    );
  }
}

class OverviewNotifier extends StateNotifier<OverviewState> {
  final RecordRepository _recordRepository;
  final PaymentRepository _paymentRepository;

  OverviewNotifier(this._recordRepository, this._paymentRepository)
    : super(OverviewState());

  Future<void> fetchTimeline(int travelId, DateTime date) async {
    state = state.copyWith(
      status: OverviewStatus.loading,
      lastTravelId: travelId,
      lastDate: date,
    );
    try {
      final dateString = date.toIso8601String();
      final recordsFuture = _recordRepository.getRecords(travelId, dateString);
      final paymentsFuture = _paymentRepository.getPayments(
        travelId,
        dateString,
        '',
      );

      final List<RecordResponse> records = await recordsFuture;
      final List<PaymentResponse> payments = await paymentsFuture;

      final List<TimelineItem> timelineItems = [];

      for (var record in records) {
        timelineItems.add(
          TimelineItem(
            type: TimelineItemType.record,
            timestamp: DateTime.parse(record.recordTime),
            data: record,
          ),
        );
      }

      for (var payment in payments) {
        timelineItems.add(
          TimelineItem(
            type: TimelineItemType.payment,
            timestamp: DateTime.parse(payment.payTime),
            data: payment,
          ),
        );
      }

      timelineItems.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      state = state.copyWith(
        status: OverviewStatus.success,
        items: timelineItems,
      );
    } catch (e) {
      state = state.copyWith(
        status: OverviewStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// 마지막 조회 조건으로 재조회
  Future<void> refreshLast() async {
    final t = state.lastTravelId;
    final d = state.lastDate;
    if (t != null && d != null) {
      await fetchTimeline(t, d);
    }
  }

  /// 삭제(기존)
  void removePayment(int paymentId) {
    final filtered = state.items
        .where(
          (it) =>
              it.type != TimelineItemType.payment ||
              it.payment.paymentId != paymentId,
        )
        .toList();
    state = state.copyWith(items: filtered);
  }

  void removeRecord(int recordId) {
    final filtered = state.items
        .where(
          (it) =>
              it.type != TimelineItemType.record ||
              it.record.travelRecordId != recordId,
        )
        .toList();
    state = state.copyWith(items: filtered);
  }
}

final overviewNotifierProvider =
    StateNotifierProvider<OverviewNotifier, OverviewState>((ref) {
      final recordRepository = ref.watch(recordRepositoryProvider);
      final paymentRepository = ref.watch(paymentRepositoryProvider);
      return OverviewNotifier(recordRepository, paymentRepository);
    });
