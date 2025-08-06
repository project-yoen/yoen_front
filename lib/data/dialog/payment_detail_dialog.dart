import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/payment_detail_response.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:intl/intl.dart';

class PaymentDetailDialog extends ConsumerStatefulWidget {
  final int paymentId;

  const PaymentDetailDialog({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentDetailDialog> createState() =>
      _PaymentDetailDialogState();
}

class _PaymentDetailDialogState extends ConsumerState<PaymentDetailDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(paymentNotifierProvider.notifier)
          .getPaymentDetails(widget.paymentId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentNotifierProvider);

    return AlertDialog(
      title: Text(state.selectedPayment?.paymentName ?? '결제 상세'),
      content: _buildContent(state),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Widget _buildContent(PaymentState state) {
    switch (state.getDetailsStatus) {
      case Status.loading:
        return const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        );
      case Status.error:
        return Text('오류: ${state.errorMessage}');
      case Status.success:
        final detail = state.selectedPayment;
        if (detail == null) {
          return const Text('상세 정보를 불러올 수 없습니다.');
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('결제자: ${detail.payerName?.travelNickName ?? '-'}'),
              Text(
                '금액: ${NumberFormat('#,###').format(detail.paymentAccount)}원',
              ),
              Text('카테고리: ${detail.categoryName ?? '-'}'),
              Text('결제수단: ${detail.paymentMethod ?? '-'}'),
              Text('환율: ${detail.exchangeRate ?? '-'}'),
              Text('시간: ${detail.payTime ?? '-'}'),
              const SizedBox(height: 16),
              const Text(
                '정산 정보',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (detail.settlements != null && detail.settlements!.isNotEmpty)
                ...detail.settlements!.map(
                  (settlement) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${settlement.settlementName} (${NumberFormat('#,###').format(settlement.amount)}원)',
                        ),
                        Text('  정산 여부: ${settlement.isPaid ? '완료' : '미완료'}'),
                        if (settlement.travelUsers.isNotEmpty)
                          Text(
                            '  대상자: ${settlement.travelUsers.map((u) => u.travelNickName).join(', ')}',
                            style: const TextStyle(fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                )
              else
                const Text(
                  '정산 내역이 없습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }
}
