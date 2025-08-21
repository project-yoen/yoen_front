import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
// 공용 다이얼로그 & 타일
import 'package:yoen_front/data/dialog/confirm.dart';
import 'package:yoen_front/data/dialog/openers.dart';
import 'package:yoen_front/data/enums/status.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/widget/payment_tile.dart';
import 'package:yoen_front/view/payment_update.dart';
import 'package:yoen_front/view/travel_sharedfund_update.dart';

import '../data/model/payment_response.dart';
import '../data/notifier/payment_notifier.dart';

class TravelPaymentScreen extends ConsumerStatefulWidget {
  const TravelPaymentScreen({super.key});

  @override
  ConsumerState<TravelPaymentScreen> createState() =>
      _TravelPaymentScreenState();
}

class _TravelPaymentScreenState extends ConsumerState<TravelPaymentScreen> {
  ProviderSubscription<DateTime?>? _dateSub;

  @override
  void initState() {
    super.initState();

    // // 초진입시 데이터 로드
    // WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPayments());

    // build 바깥에서 1회만 구독
    _dateSub = ref.listenManual<DateTime?>(dateNotifierProvider, (prev, next) {
      if (prev != next) {
        // 빌드 완료 후 호출
        WidgetsBinding.instance.addPostFrameCallback((_) => _fetchPayments());
      }
    });
  }

  @override
  void dispose() {
    _dateSub?.close();
    super.dispose();
  }

  void _fetchPayments() {
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    final date = ref.read(dateNotifierProvider);
    if (travel != null && date != null) {
      ref
          .read(paymentNotifierProvider.notifier)
          .getPayments(travel.travelId, date, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentStatus = ref.watch(
      paymentNotifierProvider.select((s) => s.getStatus),
    );
    final errorMessage = ref.watch(
      paymentNotifierProvider.select((s) => s.errorMessage),
    );
    final payments = ref.watch(filteredPaymentsProvider);

    return Column(
      children: [
        _buildFilterButtons(),
        Expanded(child: _buildBody(paymentStatus, payments, errorMessage)),
      ],
    );
  }

  Widget _buildFilterButtons() {
    // 꼭 필요한 필드만 구독 (리빌드 최소화)
    final selectedType = ref.watch(
      paymentNotifierProvider.select((s) => s.selectedType),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterButton(context, 'ALL', '전체', selectedType),
          const SizedBox(width: 8),
          _buildFilterButton(context, 'PAYMENT', '결제', selectedType),
          const SizedBox(width: 8),
          _buildFilterButton(context, 'SHAREDFUND', '공금', selectedType),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context,
    String type,
    String text,
    String selectedType,
  ) {
    final isSelected = selectedType == type;
    return ElevatedButton(
      onPressed: () {
        ref.read(paymentNotifierProvider.notifier).setSelectedType(type);
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.primary,
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
        elevation: 0,
      ),
      child: Text(text),
    );
  }

  Widget _buildBody(
    Status status,
    List<PaymentResponse> payments,
    String? error,
  ) {
    switch (status) {
      case Status.loading:
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (_, __) => const _PaymentCardSkeleton(),
        );

      case Status.error:
        return Center(child: Text('오류가 발생했습니다: $error'));

      case Status.success:
        final travel = ref.read(travelListNotifierProvider).selectedTravel;
        final date = ref.read(dateNotifierProvider);

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            if (travel != null && date != null) {
              // 새로고침 시에도 전체 목록을 다시 가져옵니다.
              await ref
                  .read(paymentNotifierProvider.notifier)
                  .getPayments(travel.travelId, date, null);
            }
          },
          child: payments.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('이 날짜에 작성된 금액기록이 없습니다.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
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
                            content: '${payment.paymentName}을(를) 삭제하시겠습니까?',
                          );
                          if (ok) {
                            await ref
                                .read(paymentNotifierProvider.notifier)
                                .deletePayment(payment.paymentId);
                          }
                        } else if (action == 'edit') {
                          await ref
                              .read(paymentNotifierProvider.notifier)
                              .getPaymentDetails(payment.paymentId);
                          final detail = ref
                              .read(paymentNotifierProvider)
                              .selectedPayment!;
                          final type = (detail.paymentType ?? '').toUpperCase();

                          // paymentType에 따라 다른 수정 화면으로 분기
                          final route = (type == 'SHAREDFUND')
                              ? MaterialPageRoute<bool>(
                                  builder: (_) => TravelSharedfundUpdateScreen(
                                    paymentId: payment.paymentId,
                                    travelId: detail.travelId!,
                                  ),
                                )
                              : MaterialPageRoute<bool>(
                                  builder: (_) => PaymentUpdateScreen(
                                    paymentId: payment.paymentId,
                                    travelId: detail.travelId!,
                                    paymentType: type, // 'PAYMENT' 등
                                  ),
                                );

                          final saved = await Navigator.of(
                            context,
                          ).push<bool>(route);
                        }
                      },
                    );
                  },
                ),
        );

      default:
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
