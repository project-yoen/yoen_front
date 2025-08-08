import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/notifier/travel_detail_notifier.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';
import 'package:yoen_front/view/travel_user_join.dart';
import 'package:yoen_front/view/travel_user_list.dart';

import '../data/notifier/travel_list_notifier.dart';
import '../data/notifier/travel_notifier.dart';
import '../data/widget/progress_badge.dart';

class TravelDetailPage extends ConsumerStatefulWidget {
  final int travelId;
  const TravelDetailPage({super.key, required this.travelId});

  @override
  ConsumerState<TravelDetailPage> createState() => _TravelDetailPageState();
}

class _TravelDetailPageState extends ConsumerState<TravelDetailPage> {
  final ImagePicker _picker = ImagePicker();

  File? _localPreview; // 로컬 프리뷰
  bool _uploading = false; // 업로드 진행 표시/버튼잠금
  int _bustSeed = 0; // 캐시 버스팅용 시드

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(travelDetailNotifierProvider.notifier)
          .getTravelDetail(widget.travelId),
    );
  }

  Future<void> _pickAndUpload() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 90,
      );
      if (picked == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('선택된 이미지가 없습니다.')));
        return;
      }

      setState(() {
        _localPreview = File(picked.path); // 즉시 프리뷰
        _uploading = true; // 로딩 시작
      });

      await ref
          .read(travelNotifierProvider.notifier)
          .updateImageNew(widget.travelId, File(picked.path));

      if (!mounted) return;
      setState(() {
        // 완료 후에도 localPreview 유지 (null로 만들지 않음)
        _bustSeed = DateTime.now().millisecondsSinceEpoch; // 써도 되고, 안 써도 됨
        _uploading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('업로드 완료')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false; // 안전하게 종료
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travelDetailNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('여행 상세 정보')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(TravelDetailState state) {
    switch (state.status) {
      case TravelDetailStatus.loading:
        return const Center(child: ProgressBadge(label: '시작 준비 중'));
      case TravelDetailStatus.error:
        return Center(child: Text('오류: ${state.errorMessage}'));
      case TravelDetailStatus.success:
        final detail = state.travelDetail;
        if (detail == null) {
          return const Center(child: Text('상세 정보를 불러올 수 없습니다.'));
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_localPreview != null)
                // 업로드 직후 로컬 프리뷰 먼저 표시
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_localPreview!, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: ElevatedButton.icon(
                        onPressed: _uploading ? null : _pickAndUpload,
                        icon: _uploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ), // 흰색
                                  backgroundColor: Colors.white24, // 대비용 배경
                                ),
                              )
                            : const Icon(Icons.upload),
                        label: Text(
                          _uploading ? '업로드 중...' : '사진 변경',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, // 굵게
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87, // 더 진한 배경
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else if (detail.travelImageUrl != null &&
                  detail.travelImageUrl!.isNotEmpty)
                Stack(
                  children: [
                    // 🔹 캐시 버스팅(+ 위젯 리빌드 강제)
                    Builder(
                      builder: (_) {
                        final url = detail.travelImageUrl!;
                        final sep = url.contains('?') ? '&' : '?';
                        final bustedUrl = _bustSeed > 0
                            ? '$url${sep}v=$_bustSeed'
                            : url;

                        return KeyedSubtree(
                          key: ValueKey(
                            'travelImage_${_bustSeed}_${url.hashCode}',
                          ),
                          child: ResponsiveShimmerImage(
                            imageUrl: bustedUrl,
                            aspectRatio: 16 / 9,
                          ),
                        );
                      },
                    ),

                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: ElevatedButton.icon(
                        onPressed: _uploading ? null : _pickAndUpload,
                        icon: _uploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload),
                        label: Text(_uploading ? '업로드 중...' : '사진 변경'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                GestureDetector(
                  onTap: _uploading ? null : _pickAndUpload,
                  child: Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),
              _buildInfoRow('국가', detail.nation),
              _buildInfoRow(
                '기간',
                '${DateFormat('yyyy.MM.dd').format(DateTime.parse(detail.startDate))} - ${DateFormat('yyyy.MM.dd').format(DateTime.parse(detail.endDate))}',
              ),
              _buildInfoRow(
                '인원',
                '${detail.numOfJoinedPeople} / ${detail.numOfPeople}',
              ),
              _buildInfoRow(
                '공금 잔액',
                '${NumberFormat('#,###').format(detail.sharedFund)}원',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  //여행 생성하기 버튼 누를 시 동작
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelUserJoinScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('신청자 리스트', style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  //여행 생성하기 버튼 누를 시 동작
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelUserListScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('유저 리스트', style: TextStyle(fontSize: 18)),
              ),
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
