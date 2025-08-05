import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/dialog/record_detail_dialog.dart';
import 'package:yoen_front/data/model/payment_response.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/model/timeline_item.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/overview_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';

class TravelOverviewContentScreen extends ConsumerStatefulWidget {
  const TravelOverviewContentScreen({super.key});

  @override
  ConsumerState<TravelOverviewContentScreen> createState() =>
      _TravelOverviewContentScreenState();
}

class _TravelOverviewContentScreenState
    extends ConsumerState<TravelOverviewContentScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _fetchData();
    });
  }

  void _fetchData() {
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    final date = ref.read(dateNotifierProvider);
    if (travel != null && date != null) {
      ref
          .read(overviewNotifierProvider.notifier)
          .fetchTimeline(travel.travelId, date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(overviewNotifierProvider);
    final travel = ref.watch(travelListNotifierProvider).selectedTravel;

    ref.listen<DateTime?>(dateNotifierProvider, (previous, next) {
      if (travel != null && previous != next && next != null) {
        ref
            .read(overviewNotifierProvider.notifier)
            .fetchTimeline(travel.travelId, next);
      }
    });

    if (travel == null) {
      return const Center(child: Text("여행 정보가 없습니다."));
    }
    final date = ref.watch(dateNotifierProvider);
    return _buildBody(overviewState, travel.travelId, date);
  }

  Widget _buildBody(OverviewState state, int travelId, DateTime? date) {
    switch (state.status) {
      case OverviewStatus.initial:
      case OverviewStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case OverviewStatus.error:
        return Center(child: Text('오류가 발생했습니다: ${state.errorMessage}'));
      case OverviewStatus.success:
        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            if (date != null) {
              await ref
                  .read(overviewNotifierProvider.notifier)
                  .fetchTimeline(travelId, date);
            }
          },
          child: state.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 200),
                    Center(child: Text('작성된 기록이 없습니다.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    if (item.type == TimelineItemType.record) {
                      return _buildRecordCard(item.record);
                    } else {
                      return _buildPaymentCard(item.payment);
                    }
                  },
                ),
        );
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
        ).then((_) => _fetchData());
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
                  Row(
                    children: [
                      const Icon(Icons.camera_alt,
                          color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        record.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
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

  Widget _buildPaymentCard(PaymentResponse payment) {
    final paymentTime = DateTime.parse(payment.payTime);
    final formattedTime = DateFormat('a h:mm', 'ko_KR').format(paymentTime);
    final formattedAmount =
        NumberFormat('#,###').format(payment.paymentAccount);

    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(payment.paymentName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('결제자: ${payment.payer}'),
                Text('금액: $formattedAmount원'),
                Text('카테고리: ${payment.categoryName}'),
                Text(
                    '시간: ${DateFormat('yyyy-MM-dd HH:mm').format(paymentTime)}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ],
          ),
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
                  Row(
                    children: [
                      const Icon(Icons.credit_card,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        payment.paymentName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
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
                '결제자: ${payment.payer}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$formattedAmount원',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                ),
              ),
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