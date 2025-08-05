import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/view/travel_payment_create.dart';
import 'package:yoen_front/view/travel_prepayment_create.dart';
import 'package:yoen_front/view/travel_sharedfund_create.dart';

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

    ref.listen<DateTime?>(dateNotifierProvider, (previous, next) {
      if (previous != next) {
        _fetchPayments();
      }
    });

    if (travel == null) {
      return const Scaffold(body: Center(child: Text("여행 정보가 없습니다.")));
    }

    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(paymentNotifierProvider);
          switch (state.getStatus) {
            case Status.loading:
              return const Center(child: CircularProgressIndicator());
            case Status.error:
              return Center(child: Text(state.errorMessage ?? "에러가 발생했습니다."));
            case Status.success:
              if (state.payments.isEmpty) {
                return const Center(child: Text("기록이 없습니다."));
              }
              return ListView.builder(
                itemCount: state.payments.length,
                itemBuilder: (context, index) {
                  final payment = state.payments[index];
                  return ListTile(
                    title: Text(payment.paymentName),
                    subtitle: Text(
                      '${payment.payerType} - ${payment.paymentAccount.toStringAsFixed(2)} ${payment.categoryId}',
                    ),
                  );
                },
              );
            case Status.initial:
            default:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPaymentOptions(context, travel.travelId),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPaymentOptions(BuildContext context, int travelId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('공금기록'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => TravelSharedfundCreateScreen(
                          travelId: travelId,
                          paymentType: "SHAREDFUND",
                        ),
                      ),
                    )
                    .then((value) {
                      if (value == true) {
                        _fetchPayments();
                      }
                    });
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment),
              title: const Text('결제기록'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => TravelPaymentCreateScreen(
                          paymentType: "PAYMENT",
                          travelId: travelId,
                        ),
                      ),
                    )
                    .then((value) {
                      if (value == true) {
                        _fetchPayments();
                      }
                    });
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('사전사용금액기록'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => TravelPrepaymentCreateScreen(
                          paymentType: "PREPAYMENT",
                          travelId: travelId,
                        ),
                      ),
                    )
                    .then((value) {
                      if (value == true) {
                        _fetchPayments();
                      }
                    });
              },
            ),
          ],
        );
      },
    );
  }
}
