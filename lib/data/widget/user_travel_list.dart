import 'package:yoen_front/data/dialog/travel_user_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';
import '../../view/travel_overview.dart';
import '../notifier/common_provider.dart';
import '../notifier/travel_list_notifier.dart';
import 'package:yoen_front/view/travel_list_all_screen.dart';
import 'package:shimmer/shimmer.dart';

// Todo: 여행 이름 길이에 따라서 처리 필요
class UserTravelList extends ConsumerStatefulWidget {
  const UserTravelList({super.key});

  @override
  ConsumerState<UserTravelList> createState() => _UserTravelListState();
}

class _UserTravelListState extends ConsumerState<UserTravelList> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: ref.read(travelListNotifierProvider).selectedIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TravelListState>(travelListNotifierProvider, (previous, next) {
      if (next.status == TravelListStatus.success && next.travels.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.microtask(() {
            if (_pageController.hasClients &&
                _pageController.page?.round() != next.selectedIndex) {
              _pageController.jumpToPage(next.selectedIndex);
            }
          });
        });
      }
    });

    final travelListState = ref.watch(travelListNotifierProvider);

    return Column(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.50,
          child: switch (travelListState.status) {
            TravelListStatus.loading ||
            TravelListStatus.initial => PageView.builder(
              controller: _pageController,
              itemCount: 3,
              itemBuilder: (context, index) => const _TravelCardSkeleton(),
            ),

            TravelListStatus.error => Center(
              child: Text(
                travelListState.errorMessage ?? '여행 목록을 불러오는데 실패했습니다.',
              ),
            ),

            TravelListStatus.success =>
              travelListState.travels.isEmpty
                  ? const Center(child: Text('아직 참여중인 여행이 없어요.'))
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        ref
                            .read(travelListNotifierProvider.notifier)
                            .setSelectedIndex(index);
                      },
                      itemCount: travelListState.travels.length,
                      itemBuilder: (context, index) {
                        final travel = travelListState.travels[index];
                        return GestureDetector(
                          onTap: () async {
                            ref
                                .read(travelListNotifierProvider.notifier)
                                .selectTravel(travel);

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const TravelOverviewScreen(),
                              ),
                            );
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
                                if ((travel.travelImageUrl ?? '').isNotEmpty)
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: () {
                                      ref
                                              .read(dialogOpenProvider.notifier)
                                              .state =
                                          true;
                                      showDialog(
                                        context: context,
                                        builder: (_) => TravelUserDialog(
                                          travelId: travel.travelId,
                                        ),
                                      ).then((_) {
                                        ref
                                                .read(
                                                  dialogOpenProvider.notifier,
                                                )
                                                .state =
                                            false;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.people,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${travel.numOfPeople}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
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

// ─────────────────────────────────────────────────────────────────────────────
// 스켈레톤 카드 (ResponsiveShimmerImage 톤에 맞춘 대체 UI)
// ─────────────────────────────────────────────────────────────────────────────
class _TravelCardSkeleton extends StatelessWidget {
  const _TravelCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    final highlight = Theme.of(
      context,
    ).colorScheme.surfaceVariant.withOpacity(.85);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지 자리 스켈레톤
          Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Container(color: base),
          ),
          // 하단 그라데이션 + 제목 자리 바
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
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Shimmer.fromColors(
                baseColor: Colors.white30,
                highlightColor: Colors.white54,
                child: Container(
                  height: 22,
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          // 우상단 인원 배지 자리
          Positioned(
            top: 8,
            right: 8,
            child: Shimmer.fromColors(
              baseColor: Colors.black26,
              highlightColor: Colors.black38,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.people, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    _Bar(width: 20, height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final double height;
  const _Bar({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white30,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
