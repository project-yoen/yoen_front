import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
// 공용 다이얼로그 & 타일
import 'package:yoen_front/data/dialog/confirm.dart';
import 'package:yoen_front/data/dialog/openers.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/widget/record_tile.dart';
import 'package:yoen_front/view/travel_record_update.dart';

class TravelRecordScreen extends ConsumerStatefulWidget {
  const TravelRecordScreen({super.key});

  @override
  ConsumerState<TravelRecordScreen> createState() => _TravelRecordScreenState();
}

class _TravelRecordScreenState extends ConsumerState<TravelRecordScreen> {
  ProviderSubscription<DateTime?>? _dateSub;

  @override
  void initState() {
    super.initState();

    // 초진입 1회 로드
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRecords());

    // 날짜 변경 구독 (build 바깥)
    _dateSub = ref.listenManual<DateTime?>(dateNotifierProvider, (prev, next) {
      if (prev != next && next != null) {
        // 프레임 이후 안전 호출
        WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRecords());
      }
    });
  }

  @override
  void dispose() {
    _dateSub?.close();
    super.dispose();
  }

  void _fetchRecords() {
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    final date = ref.read(dateNotifierProvider);
    if (travel != null && date != null) {
      ref
          .read(recordNotifierProvider.notifier)
          .getRecords(travel.travelId, date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordState = ref.watch(recordNotifierProvider);
    return Scaffold(body: _buildBody(recordState));
  }

  Widget _buildBody(RecordState state) {
    switch (state.getStatus) {
      case Status.loading:
        // 스켈레톤 리스트
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (_, __) => const _RecordCardSkeleton(),
        );

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
                    Center(child: Text('이 날짜에 작성된 여행기록이 없습니다.')),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.records.length,
                  itemBuilder: (context, index) {
                    final record = state.records[index];
                    return RecordTile(
                      record: record,
                      // 상세 보기 후에는 리패치 안 함
                      onTap: () async {
                        ref
                            .read(recordNotifierProvider.notifier)
                            .setSelectedRecord(record);
                        await openRecordDetailDialog(context);
                      },
                      // 삭제 등 상태 변경시에만 리패치
                      onMenuAction: (action) async {
                        if (action == 'delete') {
                          final ok = await showConfirmDialog(
                            context,
                            title: '기록 삭제',
                            content: '\'${record.title}\'을(를) 삭제하시겠습니까?',
                          );
                          if (ok) {
                            await ref
                                .read(recordNotifierProvider.notifier)
                                .deleteRecord(record.travelRecordId);
                            _fetchRecords();
                          }
                        } else if (action == 'edit') {
                          // TODO: 수정 다이얼로그 연결 시 변경 발생하면 _fetchRecords();
                          final travel = ref
                              .read(travelListNotifierProvider)
                              .selectedTravel;
                          if (travel == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('여행 정보가 없습니다.')),
                              );
                            }
                            return;
                          }

                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => TravelRecordUpdateScreen(
                                travelId: travel.travelId,
                                record: record, // 리스트에서 넘겨받은 RecordResponse 그대로
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        );

      default:
        // 초기 등 기타 상태도 스켈레톤
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: 6,
          itemBuilder: (_, __) => const _RecordCardSkeleton(),
        );
    }
  }
}

// ───────────────────────── 스켈레톤 ─────────────────────────
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
              // 제목 + 시간 자리
              Row(
                children: [
                  Container(
                    width: 180,
                    height: 18,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 14,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 작성자 라인 자리
              Container(
                width: 140,
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
