import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/view/travel_record_create.dart';

class TravelRecordScreen extends ConsumerWidget {
  final int travelId;
  final DateTime startDate;
  final DateTime endDate;

  const TravelRecordScreen({
    super.key,
    required this.travelId,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDate = ref.watch(dateNotifierProvider);

    return Scaffold(
      body: Center(
        child: Text('여행 기록 페이지: \${travelId}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TravelRecordCreateScreen(travelId: travelId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}