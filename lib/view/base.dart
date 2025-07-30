import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/login_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/view/travel_overview.dart';
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
    final travelListState = ref.watch(travelListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${user?.name}', // 하드코딩된 닉네임
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '여행 일정',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.50,
              child: switch (travelListState.status) {
                TravelListStatus.loading ||
                TravelListStatus.initial =>
                  const Center(child: CircularProgressIndicator()),
                TravelListStatus.error => Center(
                    child: Text(
                        travelListState.errorMessage ?? '여행 목록을 불러오는데 실패했습니다.')),
                TravelListStatus.success => travelListState.travels.isEmpty
                    ? const Center(child: Text('아직 참여중인 여행이 없어요.'))
                    : PageView.builder(
                        itemCount: travelListState.travels.length,
                        itemBuilder: (context, index) {
                          final travel = travelListState.travels[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TravelOverviewScreen(
                                    travelId: travel.travelId,
                                    travelName: travel.travelName,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (travel.imageUrl != null)
                                    Image.network(
                                      travel.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          const Center(
                                              child: Icon(Icons.error)),
                                    )
                                  else
                                    Container(
                                      color: Colors.grey[300],
                                      child: const Center(
                                          child: Icon(Icons.image_not_supported)),
                                    ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.7),
                                          ],
                                        ),
                                      ),
                                      child: Text(
                                        travel.travelName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              },
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
