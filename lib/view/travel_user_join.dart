import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    // 에러 감시
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listen<TravelJoinState>(travelJoinNotifierProvider, (previous, next) {
        if (previous?.status != next.status &&
            next.status == TravelJoinStatus.error &&
            next.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travelJoinNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent, // 그림자 아예 제거
        title: const Text('신청 여행 목록'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(joinNotifierProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),

      body: Builder(
        builder: (_) {
          switch (state.status) {
            case TravelJoinStatus.initial:
            case TravelJoinStatus.loading:
              return const Center(child: CircularProgressIndicator());

            case TravelJoinStatus.success:
              return RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.mediumImpact();
                  await ref
                      .read(travelJoinNotifierProvider.notifier)
                      .getTravelJoinList(_travelId);
                },
                child: state.userJoins.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 200),
                          Center(child: Text('신청자가 없습니다.')),
                        ],
                      )
                    : ListView.builder(
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
                      ),
              );

            case TravelJoinStatus.error:
              return const Center(child: Text('문제가 발생했습니다.'));
          }
        },
      ),
    );
  }
}
