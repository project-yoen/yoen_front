import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/model/user_response.dart';
import '../data/notifier/join_notifier.dart';
import '../data/widget/user_travel_check_tile.dart';

class UserTravelJoinScreen extends ConsumerStatefulWidget {
  const UserTravelJoinScreen({super.key});

  @override
  ConsumerState<UserTravelJoinScreen> createState() =>
      _UserTravelJoinScreenState();
}

class _UserTravelJoinScreenState extends ConsumerState<UserTravelJoinScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 첫 진입 시 API 호출
    Future.microtask(
      () => ref.read(joinNotifierProvider.notifier).getUserJoinList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(joinNotifierProvider);

    Widget body;
    switch (state.status) {
      case JoinStatus.initial:
      case JoinStatus.loading:
        body = const Center(child: CircularProgressIndicator());
        break;

      case JoinStatus.success:
        if (state.userJoins.isEmpty) {
          body = const Center(child: Text('신청한 여행이 없습니다.'));
        } else {
          body = ListView.builder(
            itemCount: state.userJoins.length,
            itemBuilder: (context, index) {
              final join = state.userJoins[index];
              return UserTravelCheckTile(
                travelId: join.travelId,
                travelName: join.travelName,
                nation: join.nation,
                users: join.users,
                onCancel: () => ref
                    .read(joinNotifierProvider.notifier)
                    .deleteTravelJoin(join.travelJoinId),
              );
            },
          );
        }
        break;

      case JoinStatus.error:
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
