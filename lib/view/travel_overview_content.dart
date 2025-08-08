import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yoen_front/data/model/timeline_item.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/overview_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';

// 삭제/수정 등 액션을 실제로 수행하려면 각 노티파이어 import
import 'package:yoen_front/data/notifier/record_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';

// 공용 타일 & 다이얼로그 오프너 & 컨펌
import '../data/dialog/confirm.dart';
import '../data/dialog/openers.dart';
import '../data/widget/payment_tile.dart';
import '../data/widget/record_tile.dart';

class TravelOverviewContentScreen extends ConsumerStatefulWidget {
  const TravelOverviewContentScreen({super.key});

  @override
  ConsumerState<TravelOverviewContentScreen> createState() =>
      _TravelOverviewContentScreenState();
}

class _TravelOverviewContentScreenState
    extends ConsumerState<TravelOverviewContentScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_fetchData);
  }

  void _fetchData() {
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    final date = ref.read(dateNotifierProvider);
    if (travel != null && date != null) {
      ref
          .read(overviewNotifierProvider.notifier)
          .fetchTimeline(travel.travelId, date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(overviewNotifierProvider);
    final travel = ref.watch(travelListNotifierProvider).selectedTravel;

    ref.listen<DateTime?>(dateNotifierProvider, (previous, next) {
      if (travel != null && previous != next && next != null) {
        ref
            .read(overviewNotifierProvider.notifier)
            .fetchTimeline(travel.travelId, next);
      }
    });

    if (travel == null) {
      return const Center(child: Text("여행 정보가 없습니다."));
    }
    final date = ref.watch(dateNotifierProvider);
    return _buildBody(overviewState, travel.travelId, date);
  }

  Widget _buildBody(OverviewState state, int travelId, DateTime? date) {
    switch (state.status) {
      case OverviewStatus.initial:
      case OverviewStatus.loading:
        // 스켈레톤 리스트
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (context, i) => i.isEven
              ? const _RecordCardSkeleton()
              : const _PaymentCardSkeleton(),
        );

      case OverviewStatus.error:
        return Center(child: Text('오류가 발생했습니다: ${state.errorMessage}'));

      case OverviewStatus.success:
        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            if (date != null) {
              await ref
                  .read(overviewNotifierProvider.notifier)
                  .fetchTimeline(travelId, date);
            }
          },
          child: state.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('이 날짜에 작성된 기록이 없습니다.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    if (item.type == TimelineItemType.record) {
                      final record = item.record;
                      return RecordTile(
                        record: record,
                        // 탭 → 기록 상세 다이얼로그 (record 화면과 동일)
                        onTap: () async {
                          await openRecordDetailDialog(context, record);
                        },
                        // 롱프레스 메뉴 → 공용 Confirm 사용 & 실제 삭제는 recordNotifier
                        onMenuAction: (action) async {
                          if (action == 'delete') {
                            final ok = await showConfirmDialog(
                              context,
                              title: '기록 삭제',
                              content: '\'${record.title}\'을(를) 삭제하시겠습니까?',
                            );
                            if (ok) {
                              await ref
                                  .read(recordNotifierProvider.notifier)
                                  .deleteRecord(record.travelRecordId);
                              ref
                                  .read(overviewNotifierProvider.notifier)
                                  .removeRecord(record.travelRecordId);
                            }
                          } else if (action == 'edit') {
                            // TODO: 편집 로직 필요 시 연결
                          }
                        },
                      );
                    } else {
                      final payment = item.payment;
                      return PaymentTile(
                        payment: payment,
                        // 탭 → 결제 상세 다이얼로그 (payment 화면과 동일)
                        onTap: () async {
                          await openPaymentDetailDialog(context, payment);
                        },
                        // 롱프레스 메뉴 → 공용 Confirm 사용 & 실제 삭제는 paymentNotifier
                        onMenuAction: (action) async {
                          if (action == 'delete') {
                            final ok = await showConfirmDialog(
                              context,
                              title: '기록 삭제',
                              content:
                                  '\'${payment.paymentName}\'을(를) 삭제하시겠습니까?',
                            );
                            if (ok) {
                              await ref
                                  .read(paymentNotifierProvider.notifier)
                                  .deletePayment(payment.paymentId);
                              ref
                                  .read(overviewNotifierProvider.notifier)
                                  .removePayment(payment.paymentId);
                              // _fetchData();
                            }
                          } else if (action == 'edit') {
                            // TODO: 편집 로직 필요 시 연결
                          }
                        },
                      );
                    }
                  },
                ),
        );
    }
  }
}

// ───────────────────────── 스켈레톤들 ─────────────────────────

class _RecordCardSkeleton extends StatelessWidget {
  const _RecordCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    final highlight = Theme.of(
      context,
    ).colorScheme.surfaceVariant.withOpacity(.85);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 라인
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 160,
                    height: 18,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 50,
                    height: 14,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // 썸네일 3개 자리
              Row(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                    child: Container(
                      width: 100,
                      height: 70,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentCardSkeleton extends StatelessWidget {
  const _PaymentCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    final highlight = Theme.of(
      context,
    ).colorScheme.surfaceVariant.withOpacity(.85);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 라인
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 140,
                    height: 18,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 50,
                    height: 14,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: 100,
                height: 12,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
