import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
// 공용 다이얼로그 & 타일
import 'package:yoen_front/data/dialog/confirm.dart';
import 'package:yoen_front/data/dialog/openers.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/widget/payment_tile.dart';
import 'package:yoen_front/view/payment_update.dart';
import 'package:yoen_front/view/travel_overview.dart';

class TravelPaymentScreen extends ConsumerStatefulWidget {
  const TravelPaymentScreen({super.key});

  @override
  ConsumerState<TravelPaymentScreen> createState() =>
      _TravelPaymentScreenState();
}

class _TravelPaymentScreenState extends ConsumerState<TravelPaymentScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_fetchPayments);
  }

  void _fetchPayments() {
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    final date = ref.read(dateNotifierProvider);
    final filterType = ref.read(paymentFilterProvider);
    if (travel != null && date != null) {
      ref
          .read(paymentNotifierProvider.notifier)
          .getPayments(travel.travelId, date, filterType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final travel = ref.watch(travelListNotifierProvider).selectedTravel;
    final paymentState = ref.watch(paymentNotifierProvider);

    ref.listen<DateTime?>(dateNotifierProvider, (prev, next) {
      if (prev != next) _fetchPayments();
    });

    ref.listen<String>(paymentFilterProvider, (prev, next) {
      if (prev != next) _fetchPayments();
    });

    if (travel == null) {
      return const Scaffold(body: Center(child: Text("여행 정보가 없습니다.")));
    }

    return Scaffold(body: _buildBody(paymentState));
  }

  Widget _buildBody(PaymentState state) {
    switch (state.getStatus) {
      case Status.loading:
        // 스켈레톤 리스트
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (_, __) => const _PaymentCardSkeleton(),
        );

      case Status.error:
        return Center(child: Text('오류가 발생했습니다: ${state.errorMessage}'));

      case Status.success:
        final travel = ref.read(travelListNotifierProvider).selectedTravel;
        final date = ref.read(dateNotifierProvider);
        final filterType = ref.read(paymentFilterProvider);

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            if (travel != null && date != null) {
              await ref
                  .read(paymentNotifierProvider.notifier)
                  .getPayments(travel.travelId, date, filterType);
            }
          },
          child: state.payments.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('이 날짜에 작성된 금액기록이 없습니다.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.payments.length,
                  itemBuilder: (context, index) {
                    final payment = state.payments[index];
                    return PaymentTile(
                      payment: payment,
                      onTap: () async {
                        await openPaymentDetailDialog(context, payment);
                      },
                      onMenuAction: (action) async {
                        if (action == 'delete') {
                          final ok = await showConfirmDialog(
                            context,
                            title: '기록 삭제',
                            content: '\'${payment.paymentName}\'을(를) 삭제하시겠습니까?',
                          );
                          if (ok) {
                            await ref
                                .read(paymentNotifierProvider.notifier)
                                .deletePayment(payment.paymentId);
                            // _fetchPayments();
                          }
                        } else if (action == 'edit') {
                          await ref
                              .read(paymentNotifierProvider.notifier)
                              .getPaymentDetails(payment.paymentId);
                          final detail = ref
                              .read(paymentNotifierProvider)
                              .selectedPayment!;
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => PaymentUpdateScreen(
                                paymentId: payment.paymentId,
                                travelId: detail.travelId!, // 상세에서 travelId 사용
                                paymentType:
                                    detail.paymentType ??
                                    'PAYMENT', // 서버 규약에 맞춰 기본값
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        );

      default:
        // 초기 등 기타 상태도 스켈레톤
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (_, __) => const _PaymentCardSkeleton(),
        );
    }
  }
}

// ───────────────────────── 스켈레톤 ─────────────────────────
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            double vw(double x) => x.clamp(0, w);

            final titleW = vw(w * 0.64);
            final catW = vw(w * 0.20);
            final labelW = vw(w * 0.16);
            final valueW = vw(w * 0.26);
            final timeW = vw(w * 0.18);

            Widget bar(double width, double height) => Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            );

            return Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [bar(titleW, 18), const Spacer(), bar(catW, 14)],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          bar(labelW * .6, 10),
                          const SizedBox(width: 8),
                          bar(valueW, 16),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          bar(labelW * .6, 10),
                          const SizedBox(width: 8),
                          bar(valueW, 16),
                        ],
                      ),
                      bar(timeW, 12),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
