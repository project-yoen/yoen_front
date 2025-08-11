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
      appBar: AppBar(title: const Text('전체 여행')),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(travelListNotifierProvider.notifier).fetchTravels();
        },
        child: switch (travelListState.status) {
          // ✅ 로딩/초기: 스켈레톤 그리드
          TravelListStatus.loading ||
          TravelListStatus.initial => const _TravelSkeletonGrid(),

          TravelListStatus.error => Center(
            child: Text(travelListState.errorMessage ?? '여행 목록을 불러오는데 실패했습니다.'),
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
                          childAspectRatio: 0.75,
                        ),
                    itemCount: travelListState.travels.length,
                    itemBuilder: (context, index) {
                      final travel = travelListState.travels[index];
                      return GestureDetector(
                        onTap: () {
                          final notifier = ref.read(
                            travelListNotifierProvider.notifier,
                          );
                          notifier.setSelectedIndex(index);
                          notifier.selectTravel(travel);

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

/// --------------------
/// Skeleton Widgets
/// --------------------

class _TravelSkeletonGrid extends StatelessWidget {
  const _TravelSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    // 화면 너비에 맞춰 적당한 아이템 수를 보여주기 위해 9개 정도로 고정
    const itemCount = 9;

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      itemCount: itemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, __) => const _TravelSkeletonCard(),
    );
  }
}

class _TravelSkeletonCard extends StatelessWidget {
  const _TravelSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 이미지 영역 스켈레톤
          Expanded(
            child: _ShimmerBox(
              borderRadius: BorderRadius.zero,
              baseColor: c.surfaceVariant.withOpacity(.55),
              highlightColor: c.surface.withOpacity(.6),
            ),
          ),
          // 제목 바 스켈레톤
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.transparent,
            child: _ShimmerBox(
              height: 14,
              borderRadius: BorderRadius.circular(6),
              baseColor: c.surfaceVariant.withOpacity(.55),
              highlightColor: c.surface.withOpacity(.6),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// 아주 가벼운 커스텀 Shimmer (외부 패키지 없이)
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerBox({
    this.width,
    this.height,
    this.borderRadius,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? double.infinity;
    final height = widget.height ?? double.infinity;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final percent = _controller.value;
        // 3-stop 그라데이션을 좌→우로 이동
        final gradient = LinearGradient(
          begin: Alignment(-1.0 + percent * 2, 0),
          end: Alignment(1.0 + percent * 2, 0),
          colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
          stops: const [0.25, 0.5, 0.75],
        );

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            gradient: gradient,
          ),
        );
      },
    );
  }
}
