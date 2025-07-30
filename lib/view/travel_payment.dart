import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';

class TravelPaymentScreen extends ConsumerWidget {
  final int travelId;
  final DateTime startDate;
  final DateTime endDate;

  const TravelPaymentScreen({
    super.key,
    required this.travelId,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDate = ref.watch(dateNotifierProvider);

    return Scaffold(body: Center(child: Text('금액 기록 페이지: \${travelId}')));
  }
}
