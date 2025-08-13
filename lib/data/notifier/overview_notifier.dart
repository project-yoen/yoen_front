import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/payment_response.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/model/timeline_item.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart';

enum OverviewStatus { initial, loading, success, error }

class OverviewState {
  final OverviewStatus status;
  final List<TimelineItem> items;
  final String? errorMessage;
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
  OverviewNotifier(this.ref) : super(OverviewState());
  final Ref ref;

  /// 항상 Notifier 경유로 가져와서 상태 동기화
  Future<void> fetchTimeline(int travelId, DateTime date) async {
    state = state.copyWith(
      status: OverviewStatus.loading,
      lastTravelId: travelId,
      lastDate: date,
    );

    try {
      // 1) 각 Notifier에게 fetch 지시 (여기서 각자 last 컨텍스트도 저장됨)
      await ref
          .read(recordNotifierProvider.notifier)
          .getRecords(travelId, date);
      await ref
          .read(paymentNotifierProvider.notifier)
          .getPayments(travelId, date, ''); // 필터 없으면 빈 문자열

      // 2) 결과는 각 Notifier의 state에서 읽어서 조합
      final recordState = ref.read(recordNotifierProvider);
      final paymentState = ref.read(paymentNotifierProvider);

      final List<RecordResponse> records = recordState.records;
      final List<PaymentResponse> payments =
          paymentState.payments; // ← PaymentState에 payments 리스트가 있어야 함

      final List<TimelineItem> timelineItems = [
        for (final r in records)
          TimelineItem(
            type: TimelineItemType.record,
            timestamp: DateTime.parse(r.recordTime),
            data: r,
          ),
        for (final p in payments)
          TimelineItem(
            type: TimelineItemType.payment,
            timestamp: DateTime.parse(p.payTime),
            data: p,
          ),
      ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

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

  Future<void> refreshLast() async {
    final t = state.lastTravelId;
    final d = state.lastDate;
    if (t != null && d != null) {
      await fetchTimeline(t, d);
    }
  }

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
      return OverviewNotifier(ref);
    });
