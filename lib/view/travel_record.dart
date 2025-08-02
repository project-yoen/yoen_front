import 'package:yoen_front/data/dialog/record_detail_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';

class TravelRecordScreen extends ConsumerStatefulWidget {
  const TravelRecordScreen({super.key});

  @override
  ConsumerState<TravelRecordScreen> createState() => _TravelRecordScreenState();
}

class _TravelRecordScreenState extends ConsumerState<TravelRecordScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final travel = ref.read(travelListNotifierProvider).selectedTravel;
      final date = ref.read(dateNotifierProvider);
      if (travel != null && date != null) {
        ref
            .read(recordNotifierProvider.notifier)
            .getRecords(travel.travelId, date);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recordState = ref.watch(recordNotifierProvider);

    ref.listen<DateTime?>(dateNotifierProvider, (previous, next) {
      final travel = ref.read(travelListNotifierProvider).selectedTravel;
      if (travel != null && next != null && previous != next) {
        ref
            .read(recordNotifierProvider.notifier)
            .getRecords(travel.travelId, next);
      }
    });

    return Scaffold(body: _buildBody(recordState));
  }

  Widget _buildBody(RecordState state) {
    switch (state.getStatus) {
      case Status.loading:
        return const Center(child: CircularProgressIndicator());
      case Status.error:
        return Center(child: Text('오류가 발생했습니다: ${state.errorMessage}'));
      case Status.success:
        final travel = ref.read(travelListNotifierProvider).selectedTravel;
        final date = ref.read(dateNotifierProvider);

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            if (travel != null && date != null) {
              await ref
                  .read(recordNotifierProvider.notifier)
                  .getRecords(travel.travelId, date);
            }
          },
          child: state.records.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('이 날짜에 작성된 기록이 없습니다.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.records.length,
                  itemBuilder: (context, index) {
                    final record = state.records[index];
                    return _buildRecordCard(record);
                  },
                ),
        );
      default:
        return const Center(child: Text('기록을 불러오는 중...'));
    }
  }

  Widget _buildRecordCard(RecordResponse record) {
    final recordTime = DateTime.parse(record.recordTime);
    final formattedTime = DateFormat('a h:mm', 'ko_KR').format(recordTime);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => RecordDetailDialog(record: record),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      record.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    formattedTime,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                '작성자: ${record.travelNickName}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
              if (record.images.isNotEmpty) ...[
                const SizedBox(height: 16.0),
                _buildImageGallery(
                  record.images.map((e) => e.imageUrl).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: ResponsiveShimmerImage(imageUrl: images[index]),
            ),
          );
        },
      ),
    );
  }
}
