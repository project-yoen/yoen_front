import 'package:yoen_front/data/dialog/travel_user_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';
import '../../view/travel_overview.dart';
import '../notifier/common_provider.dart';
import '../notifier/travel_list_notifier.dart';

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
    // Controller is initialized with the last known index from the notifier.
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
    // Listen to the entire state object to ensure the listener fires when the list is reloaded.
    ref.listen<TravelListState>(travelListNotifierProvider, (previous, next) {
      // When the state is updated to success, ensure the page controller is synced.
      if (next.status == TravelListStatus.success && next.travels.isNotEmpty) {
        // Defer this logic until after the build is complete.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.microtask(() {
            // 한 프레임 더 미룸
            if (_pageController.hasClients &&
                _pageController.page?.round() != next.selectedIndex) {
              print("jump to ${next.selectedIndex}");
              _pageController.jumpToPage(next.selectedIndex);
            }
          });
        });
      }
    });

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
                      controller: _pageController,
                      onPageChanged: (index) {
                        // When the user manually swipes, update the index in the notifier.
                        ref
                            .read(travelListNotifierProvider.notifier)
                            .setSelectedIndex(index);
                      },
                      itemCount: travelListState.travels.length,
                      itemBuilder: (context, index) {
                        final travel = travelListState.travels[index];
                        return GestureDetector(
                          onTap: () async {
                            // When a travel is tapped, select it in the notifier.
                            ref
                                .read(travelListNotifierProvider.notifier)
                                .selectTravel(travel);

                            // Navigate to the overview screen.
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
                                if (travel.travelImageUrl != "")
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
