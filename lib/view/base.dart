import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/login_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/notifier/user_notifier.dart';
import 'package:yoen_front/data/widget/user_travel_list.dart';
import 'package:yoen_front/view/user_settings.dart';
import 'package:yoen_front/view/user_travel_join.dart';

import '../data/dialog/travel_code_dialog.dart';
import '../data/notifier/record_notifier.dart';
import 'login.dart';
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

      // TODO: 여행기록 리셋함수, 나중에 금액기록이나 해당 여행에서 상태관리하는 것들은 전부 초기화 해주고 다른 여행 들어가야함
      // TODO: 그렇지 않으면 다른 여행에서 상태관리하던게 뜬금없이 남아있을때가 있음
      ref.read(recordNotifierProvider.notifier).resetAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent, // 그림자 아예 제거
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        title: Align(
          alignment: Alignment.centerLeft,
          child: userAsync.when(
            data: (user) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserSettingsScreen(),
                  ),
                );
              },
              child: Text(user.name ?? '이름 없음'),
            ),
            loading: () => const CircularProgressIndicator(),
            error: (err, _) => GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: const Text(
                '오류 발생',
                style: TextStyle(fontWeight: FontWeight.bold),
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
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact(); // ← 진동 추가
          ref.read(travelListNotifierProvider.notifier).fetchTravels();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}
