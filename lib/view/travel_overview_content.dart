import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
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
        // 스켈레톤 리스트로 대체
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (context, i) => i.isEven
              ? const _RecordCardSkeleton()
              : const _PaymentCardSkeleton(),
        );

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
                    Center(child: Text('이 날짜에 작성된 기록이 없습니다.')),
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
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    // ← 왼쪽 블록을 확장시켜 공간 관리
                    child: Row(
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          // ← 텍스트에 가변 폭 부여
                          child: Text(
                            record.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // ← 말줄임
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
    final formattedAmount = NumberFormat(
      '#,###',
    ).format(payment.paymentAccount);

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
                  '시간: ${DateFormat('yyyy-MM-dd HH:mm').format(paymentTime)}',
                ),
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
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.credit_card,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            payment.paymentName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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

// ───────────────────────── 스켈레톤들 ─────────────────────────

class _RecordCardSkeleton extends StatelessWidget {
  const _RecordCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    final highlight = Theme.of(
      context,
    ).colorScheme.surfaceVariant.withOpacity(.85);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 라인
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 160,
                    height: 18,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 50,
                    height: 14,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: 120,
                height: 12,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              // 썸네일 3개 자리
              Row(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                    child: Container(
                      width: 100,
                      height: 70,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentCardSkeleton extends StatelessWidget {
  const _PaymentCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    final highlight = Theme.of(
      context,
    ).colorScheme.surfaceVariant.withOpacity(.85);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목 라인
              Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 140,
                    height: 18,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 50,
                    height: 14,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: 100,
                height: 12,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
