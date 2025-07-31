import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';

class TravelAdditionalScreen extends ConsumerWidget {
  const TravelAdditionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travel = ref.watch(travelListNotifierProvider).selectedTravel;

    if (travel == null) {
      return const Scaffold(
        body: Center(child: Text("여행 정보가 없습니다.")),
      );
    }

    return Scaffold(body: Center(child: Text('부가 기능 페이지: \${travel.travelId}')));
  }
}
