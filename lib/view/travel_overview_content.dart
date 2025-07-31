import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';

class TravelOverviewContentScreen extends ConsumerWidget {
  const TravelOverviewContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travel = ref.watch(travelListNotifierProvider).selectedTravel;

    if (travel == null) {
      return const Center(child: Text("여행 정보가 없습니다."));
    }

    return Center(child: Text('전체보기 페이지: \${travel.travelId}'));
  }
}