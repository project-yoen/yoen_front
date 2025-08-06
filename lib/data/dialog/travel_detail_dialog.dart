import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/notifier/travel_detail_notifier.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';

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
    Future.microtask(() => ref
        .read(travelDetailNotifierProvider.notifier)
        .getTravelDetail(widget.travelId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travelDetailNotifierProvider);
    return AlertDialog(
      title: const Text('여행 상세 정보'),
      content: _buildBody(state),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Widget _buildBody(TravelDetailState state) {
    switch (state.status) {
      case TravelDetailStatus.loading:
        return const SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        );
      case TravelDetailStatus.error:
        return Text('오류: ${state.errorMessage}');
      case TravelDetailStatus.success:
        final detail = state.travelDetail;
        if (detail == null) {
          return const Text('상세 정보를 불러올 수 없습니다.');
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (detail.travelImageUrl != null &&
                  detail.travelImageUrl!.isNotEmpty)
                ResponsiveShimmerImage(
                  imageUrl: detail.travelImageUrl!,
                  aspectRatio: 16 / 9,
                ),
              const SizedBox(height: 16),
              Text(
                detail.travelName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildInfoRow('국가', detail.nation),
              _buildInfoRow(
                '기간',
                '${DateFormat('yy.MM.dd').format(DateTime.parse(detail.startDate))} - ${DateFormat('yy.MM.dd').format(DateTime.parse(detail.endDate))}',
              ),
              _buildInfoRow('인원', '${detail.numOfJoinedPeople} / ${detail.numOfPeople}'),
              _buildInfoRow('공금 잔액', '${NumberFormat('#,###').format(detail.sharedFund)}원'),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
