import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/payment_response.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/view/travel_payment_create.dart';
import 'package:yoen_front/view/travel_prepayment_create.dart';
import 'package:yoen_front/data/dialog/payment_detail_dialog.dart';

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
    Future.microtask(() {
      _fetchPayments();
    });
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

    ref.listen<DateTime?>(dateNotifierProvider, (previous, next) {
      if (previous != next) {
        _fetchPayments();
      }
    });

    if (travel == null) {
      return const Scaffold(body: Center(child: Text("여행 정보가 없습니다.")));
    }

    return Scaffold(body: _buildBody(paymentState));
  }

  Widget _buildBody(PaymentState state) {
    switch (state.getStatus) {
      case Status.loading:
        return const Center(child: CircularProgressIndicator());
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
                  itemBuilder: (context, index) {
                    final payment = state.payments[index];
                    return _buildPaymentCard(payment);
                  },
                ),
        );
      default:
        return const Center(child: Text('기록을 불러오는 중...'));
    }
  }

  Widget _buildPaymentCard(PaymentResponse payment) {
    final paymentTime = DateTime.parse(payment.payTime);
    final formattedTime = DateFormat('a h:mm', 'ko_KR').format(paymentTime);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) =>
              PaymentDetailDialog(paymentId: payment.paymentId),
        );
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
              // 첫 줄: 결제이름 + 카테고리
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      payment.paymentName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
              // 두 번째 줄: 결제자 - 결제금액 - 시간
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
                        payment.payerType == 'SHAREDFUND' ? '<공금>' : payment.payer ?? '-',
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
                        '${payment.paymentAccount}원',
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
    );
  }
}
