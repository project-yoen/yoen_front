import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/login_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/widget/user_travel_list.dart';
import 'package:yoen_front/view/user_travel_join.dart';

import '../data/dialog/travel_code_dialog.dart';
import 'travel_destination.dart'; // TravelDestinationScreen 임포트 추가

class BaseScreen extends ConsumerStatefulWidget {
  const BaseScreen({super.key});

  @override
  ConsumerState<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends ConsumerState<BaseScreen> {
  @override
  void initState() {
    super.initState();
    // 위젯이 빌드된 후 첫 여행 목록을 가져옵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(travelListNotifierProvider.notifier).fetchTravels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.read(userProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        title: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () {
              showLogoutDialog(
                context,
                () => ref.read(loginNotifierProvider.notifier).logout(context),
              );
              // 클릭 시 동작 정의
              print('닉네임 클릭됨: ${user?.name}');
            },
            child: Text(
              '${user?.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline, // 밑줄 추가 (선택)
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications), // 종 아이콘
            onPressed: () {
              // 알림 버튼 클릭 시 동작
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserTravelList(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ElevatedButton(
                onPressed: () {
                  //여행 생성하기 버튼 누를 시 동작
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TravelDestinationScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('여행 생성하기', style: TextStyle(fontSize: 18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ElevatedButton(
                onPressed: () {
                  // 여행 참여하기 버튼 클릭 시 동작
                  showDialog(
                    context: context,
                    // 주변 배경 누르면 꺼지는 설정
                    barrierDismissible: false,
                    builder: (context) => const TravelCodeDialog(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('여행 참여하기', style: TextStyle(fontSize: 18)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ElevatedButton(
                onPressed: () {
                  //여행 생성하기 버튼 누를 시 동작
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserTravelJoinScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('신청한 여행', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showLogoutDialog(BuildContext context, VoidCallback onLogout) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 다이얼로그 닫기
              onLogout(); // 로그아웃 실행
            },
            child: const Text('로그아웃'),
          ),
        ],
      );
    },
  );
}
