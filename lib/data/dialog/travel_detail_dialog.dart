import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/notifier/travel_detail_notifier.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';

class TravelDetailDialog extends ConsumerStatefulWidget {
  final int travelId;
  const TravelDetailDialog({super.key, required this.travelId});

  @override
  ConsumerState<TravelDetailDialog> createState() => _TravelDetailDialogState();
}

class _TravelDetailDialogState extends ConsumerState<TravelDetailDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(travelDetailNotifierProvider.notifier)
          .getTravelDetail(widget.travelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travelDetailNotifierProvider);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 8),
          const Text('여행 상세 정보'),
          const Spacer(),
          IconButton(
            tooltip: '닫기',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: _buildBody(state, context),
      ),
    );
  }

  Widget _buildBody(TravelDetailState state, BuildContext context) {
    final c = Theme.of(context).colorScheme;

    switch (state.status) {
      case TravelDetailStatus.loading:
        return SizedBox(
          width: 340,
          height: 140,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: c.primary),
                const SizedBox(height: 10),
                const ProgressBadge(label: '불러오는 중'),
              ],
            ),
          ),
        );

      case TravelDetailStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('오류: ${state.errorMessage}'),
        );

      case TravelDetailStatus.success:
        final detail = state.travelDetail;
        if (detail == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('상세 정보를 불러올 수 없습니다.'),
          );
        }

        final start = DateTime.parse(detail.startDate);
        final end = DateTime.parse(detail.endDate);
        final period =
            '${DateFormat('yyyy.MM.dd').format(start)} - ${DateFormat('yyyy.MM.dd').format(end)}';

        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 이미지 카드
              if ((detail.travelImageUrl ?? '').isNotEmpty)
                Card(
                  margin: EdgeInsets.zero,
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ResponsiveShimmerImage(
                    imageUrl: detail.travelImageUrl!,
                    aspectRatio: 16 / 9,
                  ),
                ),
              if ((detail.travelImageUrl ?? '').isNotEmpty)
                const SizedBox(height: 14),

              // 여행명
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  detail.travelName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),

              // 정보 카드
              _SectionCard(
                child: Column(
                  children: [
                    _InfoRow(label: '국가', value: detail.nation),
                    const _MiniDivider(),
                    _InfoRow(label: '기간', value: period),
                    const _MiniDivider(),
                    _InfoRow(
                      label: '인원',
                      value:
                          '${detail.numOfJoinedPeople} / ${detail.numOfPeople}',
                    ),
                    const _MiniDivider(),
                    _InfoRow(
                      label: '공금 잔액',
                      value:
                          '${NumberFormat('#,###').format(detail.sharedFund)}원',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }
}

/// 재사용 위젯들
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: child,
      ),
    );
  }
}

class _MiniDivider extends StatelessWidget {
  const _MiniDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Divider(height: 1),
    );
  }
}

/// 한 줄 유지 정보 행 (라벨 좌 / 값 우)
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final labelStyle = tt.titleMedium?.copyWith(fontWeight: FontWeight.w600);
    final valueStyle = tt.bodyLarge;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Align(
            alignment: Alignment.centerRight,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(value, maxLines: 1, style: valueStyle),
            ),
          ),
        ),
      ],
    );
  }
}
