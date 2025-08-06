import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/notifier/travel_notifier.dart';
import 'package:yoen_front/main.dart';
import 'package:yoen_front/view/travel_detail_page.dart';
import 'package:yoen_front/view/travel_prepayment_create.dart';
import 'package:yoen_front/view/travel_user_join.dart';
import 'package:yoen_front/view/travel_user_list.dart';

import 'base.dart';

class TravelAdditionalScreen extends ConsumerWidget {
  const TravelAdditionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travel = ref.watch(travelListNotifierProvider).selectedTravel;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TravelDetailPage(travelId: travel!.travelId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('여행 정보', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  //여행 생성하기 버튼 누를 시 동작
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelUserJoinScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('신청자 리스트', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  //여행 생성하기 버튼 누를 시 동작
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelPrepaymentCreateScreen(
                        travelId: travel!.travelId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('사전 사용금액 등록', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  //여행 생성하기 버튼 누를 시 동작
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelUserListScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('유저 리스트', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  showTravelOutDialog(context, () async {
                    try {
                      // 1. 여행 나가기 API 호출
                      int travelId = ref
                          .read(travelListNotifierProvider)
                          .selectedTravel!
                          .travelId;
                      snackbarKey.currentState?.showSnackBar(
                        SnackBar(content: Text("방 나가는 중 ..")),
                      );
                      await ref
                          .read(travelNotifierProvider.notifier)
                          .leaveTravel(travelId);

                      // 3. BaseScreen으로 이동
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const BaseScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    } catch (e) {
                      // 에러 처리
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('여행 나가기에 실패했습니다.')),
                      );
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('여행 나가기', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showTravelOutDialog(BuildContext context, VoidCallback onOut) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('여행 나가기'),
        content: const Text('정말 여행을 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOut();
            },
            child: const Text('나가기'),
          ),
        ],
      );
    },
  );
}
