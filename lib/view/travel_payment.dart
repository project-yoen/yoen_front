import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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

    Offset? tapPosition;

    return GestureDetector(
      onTapDown: (TapDownDetails details) {
        // 탭 위치 기억
        tapPosition = details.globalPosition;
      },
      child: InkWell(
        onTap: () async {
          final notifier = ref.read(paymentNotifierProvider.notifier);
          await notifier.getPaymentDetails(payment.paymentId);
          final detail = ref.read(paymentNotifierProvider).selectedPayment;
          if (!context.mounted) return;

          showDialog(
            context: context,
            builder: (context) {
              if (detail == null) {
                return const AlertDialog(
                  title: Text('오류'),
                  content: Text('결제 상세 정보를 불러오지 못했습니다.'),
                );
              }

              return AlertDialog(
                title: Text(detail.paymentName ?? '결제 상세'),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('결제자: ${detail.payerName?.travelNickName ?? '-'}'),
                      Text('금액: ${detail.paymentAccount ?? '-'}원'),
                      Text('카테고리: ${detail.categoryName ?? '-'}'),
                      Text('결제수단: ${detail.paymentMethod ?? '-'}'),
                      Text('결제타입: ${detail.paymentType ?? '-'}'),
                      Text('환율: ${detail.exchangeRate ?? '-'}'),
                      Text('시간: ${detail.payTime ?? '-'}'),
                      const SizedBox(height: 16),
                      const Text(
                        '정산 정보',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (detail.settlements != null &&
                          detail.settlements!.isNotEmpty)
                        ...detail.settlements!.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ${s.settlementName} (${s.amount}원)'),
                                Text('  정산 여부: ${s.isPaid ? '완료' : '미완료'}'),
                                if (s.travelUsers.isNotEmpty)
                                  Text(
                                    '  대상자: ${s.travelUsers.map((u) => u.travelNickName).join(', ')}',
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
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
                ],
              );
            },
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
            // 수정 로직
          } else if (result == 'delete') {
            // 삭제 로직
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
                          payment.payer!,
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
      ),
    );
  }

  void _showDeleteConfirmDialog(PaymentResponse payment) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('기록 삭제'),
          content: Text('\'${payment.paymentName}\'을(를) 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                ref
                    .read(paymentNotifierProvider.notifier)
                    .deletePayment(payment.paymentId);
                Navigator.of(context).pop(); // Close confirmation dialog
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
