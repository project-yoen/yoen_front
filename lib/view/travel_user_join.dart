import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/travel_join_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';

import '../data/notifier/join_notifier.dart';
import '../data/widget/travel_join_check_tile.dart';

class TravelUserJoinScreen extends ConsumerStatefulWidget {
  const TravelUserJoinScreen({super.key});

  @override
  ConsumerState<TravelUserJoinScreen> createState() =>
      _TravelUserJoinScreenState();
}

class _TravelUserJoinScreenState extends ConsumerState<TravelUserJoinScreen> {
  int _travelId = 0;

  @override
  void initState() {
    super.initState();
    // 화면 첫 진입 시 API 호출
    Future.microtask(() {
      ref.read(travelJoinNotifierProvider.notifier).reset();
      int travelId = ref
          .read(travelListNotifierProvider)
          .selectedTravel!
          .travelId;

      setState(() {
        _travelId = travelId;
      });

      ref
          .read(travelJoinNotifierProvider.notifier)
          .getTravelJoinList(_travelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travelJoinNotifierProvider);

    Widget body;
    switch (state.status) {
      case TravelJoinStatus.initial:
      case TravelJoinStatus.loading:
        body = const Center(child: CircularProgressIndicator());
        break;

      case TravelJoinStatus.success:
        if (state.userJoins.isEmpty) {
          body = const Center(child: Text('신청자가 없습니다.'));
        } else {
          body = ListView.builder(
            itemCount: state.userJoins.length,
            itemBuilder: (context, index) {
              final join = state.userJoins[index];
              return TravelUserJoinTile(
                travelJoinId: join.travelJoinRequestId,
                name: join.name,
                gender: join.gender,
                imageUrl: join.imageUrl,
              );
            },
          );
        }
        break;

      case TravelJoinStatus.error:
        body = Center(child: Text('에러: ${state.errorMessage ?? "알 수 없는 오류"}'));
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('신청 여행 목록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(joinNotifierProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),

      body: body,
    );
  }
}
