import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';
import 'package:yoen_front/view/travel_overview.dart';

class TravelListAllScreen extends ConsumerWidget {
  const TravelListAllScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelListState = ref.watch(travelListNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('전체 여행'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(travelListNotifierProvider.notifier).fetchTravels();
        },
        child: switch (travelListState.status) {
          TravelListStatus.loading ||
          TravelListStatus.initial =>
            const Center(child: CircularProgressIndicator()),
          TravelListStatus.error => Center(
              child: Text(
                travelListState.errorMessage ?? '여행 목록을 불러오는데 실패했습니다.',
              ),
            ),
          TravelListStatus.success =>
            travelListState.travels.isEmpty
                ? const Center(child: Text('아직 참여중인 여행이 없어요.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.75, // 아이템의 가로세로 비율
                    ),
                    itemCount: travelListState.travels.length,
                    itemBuilder: (context, index) {
                      final travel = travelListState.travels[index];
                      return GestureDetector(
                        onTap: () {
                          final notifier =
                              ref.read(travelListNotifierProvider.notifier);
                          // 1. 선택된 여행의 인덱스와 정보를 Notifier에 업데이트
                          notifier.setSelectedIndex(index);
                          notifier.selectTravel(travel);

                          // 2. 상세 페이지로 이동 (현재 화면을 교체)
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TravelOverviewScreen(),
                            ),
                          );
                        },
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (travel.travelImageUrl != null &&
                                  travel.travelImageUrl!.isNotEmpty)
                                ResponsiveShimmerImage(
                                  imageUrl: travel.travelImageUrl!,
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
                                  padding: const EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withAlpha(200),
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    travel.travelName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
    );
  }
}
