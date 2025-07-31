import 'package:yoen_front/data/notifier/travel_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../view/travel_overview.dart';
import '../notifier/travel_list_notifier.dart';

class UserTravelList extends ConsumerStatefulWidget {
  const UserTravelList({super.key});

  @override
  ConsumerState<UserTravelList> createState() => _UserTravelListState();
}

class _UserTravelListState extends ConsumerState<UserTravelList> {
  @override
  Widget build(BuildContext context) {
    final travelListState = ref.watch(travelListNotifierProvider);

    return Column(
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
            TravelListStatus.loading || TravelListStatus.initial =>
              const Center(child: CircularProgressIndicator()),
            TravelListStatus.error => Center(
              child: Text(
                travelListState.errorMessage ?? '여행 목록을 불러오는데 실패했습니다.',
              ),
            ),
            TravelListStatus.success =>
              travelListState.travels.isEmpty
                  ? const Center(child: Text('아직 참여중인 여행이 없어요.'))
                  : PageView.builder(
                      itemCount: travelListState.travels.length,
                      itemBuilder: (context, index) {
                        final travel = travelListState.travels[index];
                        return GestureDetector(
                          onTap: () async {
                            // 1. 선택된 여행 정보를 전역 Notifier에 저장
                            ref
                                .read(travelListNotifierProvider.notifier)
                                .selectTravel(travel);

                            // 2. 파라미터 없이 화면 이동
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TravelOverviewScreen(),
                              ),
                            );
                            ref
                                .read(travelListNotifierProvider.notifier)
                                .fetchTravels();
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
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
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Center(
                                              child: Icon(Icons.error),
                                            ),
                                  )
                                else
                                  Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.image_not_supported),
                                    ),
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
                                          Colors.black.withAlpha(
                                            (0.7 * 255).round(),
                                          ),
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
      ],
    );
  }
}
