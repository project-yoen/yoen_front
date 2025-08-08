import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yoen_front/data/dialog/payment_detail_dialog.dart';
import 'package:yoen_front/data/model/payment_response.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';

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
    if (travel != null && date != null) {
      ref
          .read(paymentNotifierProvider.notifier)
          .getPayments(travel.travelId, date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final travel = ref.watch(travelListNotifierProvider).selectedTravel;
    final paymentState = ref.watch(paymentNotifierProvider);

    ref.listen<DateTime?>(dateNotifierProvider, (prev, next) {
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
        // 로딩 상태: 스켈레톤 리스트
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

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            if (travel != null && date != null) {
              await ref
                  .read(paymentNotifierProvider.notifier)
                  .getPayments(travel.travelId, date);
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
                  itemBuilder: (context, index) =>
                      _buildPaymentCard(state.payments[index]),
                ),
        );

      default:
        // 초기 등 기타 상태도 스켈레톤으로 통일
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (_, __) => const _PaymentCardSkeleton(),
        );
    }
  }

  Widget _buildPaymentCard(PaymentResponse payment) {
    final paymentTime = DateTime.parse(payment.payTime);
    final formattedTime = DateFormat('a h:mm', 'ko_KR').format(paymentTime);
    final formattedAmount = NumberFormat(
      '#,###',
    ).format(payment.paymentAccount);

    Offset? tapPosition;

    return GestureDetector(
      onTapDown: (d) => tapPosition = d.globalPosition,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => PaymentDetailDialog(paymentId: payment.paymentId),
          );
        },
        onLongPress: () async {
          if (tapPosition == null) return;
          final overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;

          final result = await showMenu<String>(
            context: context,
            position: RelativeRect.fromLTRB(
              tapPosition!.dx,
              tapPosition!.dy,
              overlay.size.width - tapPosition!.dx,
              overlay.size.height - tapPosition!.dy,
            ),
            items: const [
              PopupMenuItem<String>(value: 'edit', child: Text('수정')),
              PopupMenuItem<String>(value: 'delete', child: Text('삭제')),
            ],
          );

          if (result == 'edit') {
            // TODO: 수정 로직
          } else if (result == 'delete') {
            _showDeleteConfirmDialog(payment);
          }
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 결제이름 + 카테고리
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        payment.paymentName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      payment.categoryName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '결제자',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          payment.payer ?? '',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '결제금액',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$formattedAmount원',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      formattedTime,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(PaymentResponse payment) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('기록 삭제'),
          content: Text('\'${payment.paymentName}\'을(를) 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                ref
                    .read(paymentNotifierProvider.notifier)
                    .deletePayment(payment.paymentId);
                Navigator.of(context).pop();
              },
              child: const Text('예'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('아니오'),
            ),
          ],
        );
      },
    );
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

            double vw(double x) => x.clamp(0, w); // 안전장치
            // 상단 제목/카테고리: 제목은 60~70% 범위, 카테고리는 18~22% 범위
            final titleW = vw(w * 0.64);
            final catW = vw(w * 0.20);

            // 하단 라인: 라벨/값 쌍 2개 + 시간
            final labelW = vw(w * 0.16); // "결제자", "결제금액" 등
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
                  // ── 제목 + 카테고리
                  Row(
                    children: [bar(titleW, 18), const Spacer(), bar(catW, 14)],
                  ),
                  const SizedBox(height: 12),

                  // ── 결제자 / 금액 / 시간 (작은 화면에서 자동 줄바꿈 허용)
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          bar(labelW * .6, 10), // 라벨은 더 짧게
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
