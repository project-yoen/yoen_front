import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/notifier/travel_detail_notifier.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';
import 'package:yoen_front/view/travel_user_join.dart';
import 'package:yoen_front/view/travel_user_list.dart';

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
    Future.microtask(() {
      ref
          .read(travelDetailNotifierProvider.notifier)
          .getTravelDetail(widget.travelId);
    });
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
        _bustSeed = DateTime.now().millisecondsSinceEpoch;
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
        setState(() => _uploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travelDetailNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('여행 상세 정보'),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
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

        final start = DateTime.parse(detail.startDate);
        final end = DateTime.parse(detail.endDate);
        final periodText =
            '${DateFormat('yyyy.MM.dd').format(start)} - ${DateFormat('yyyy.MM.dd').format(end)}';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ===== 헤더 이미지 카드 =====
              Card(
                margin: EdgeInsets.zero,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: _buildHeaderImage(detail.travelImageUrl),
                    ),
                    // 그라데이션 오버레이
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black38, Colors.transparent],
                              stops: [0, 0.5],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // 사진 변경 버튼
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: _PhotoChangeButton(
                        uploading: _uploading,
                        onPressed: _uploading ? null : _pickAndUpload,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===== 정보 카드 (모든 항목 한 줄) =====
              _SectionCard(
                child: Column(
                  children: [
                    _InfoRow(label: '국가', value: detail.nation),
                    const _Divider16(),
                    _InfoRow(label: '기간', value: periodText),
                    const _Divider16(),
                    _InfoRow(
                      label: '인원',
                      value:
                          '${detail.numOfJoinedPeople} / ${detail.numOfPeople}',
                    ),
                    const _Divider16(),
                    _InfoRow(
                      label: '공금 잔액',
                      value:
                          '${NumberFormat('#,###').format(detail.sharedFund)}원',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===== 액션 버튼들 =====
              _ActionButton(
                icon: Icons.how_to_reg_outlined,
                label: '신청자 리스트',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TravelUserJoinScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.group_outlined,
                label: '유저 리스트',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TravelUserListScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildHeaderImage(String? imageUrl) {
    // 업로드 직후: 로컬 프리뷰 우선
    if (_localPreview != null) {
      return Image.file(_localPreview!, fit: BoxFit.cover);
    }

    // 서버 이미지
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final url = imageUrl;
      final sep = url.contains('?') ? '&' : '?';
      final bustedUrl = _bustSeed > 0 ? '$url${sep}v=$_bustSeed' : url;

      return KeyedSubtree(
        key: ValueKey('travelImage_${_bustSeed}_${url.hashCode}'),
        child: ResponsiveShimmerImage(imageUrl: bustedUrl, aspectRatio: 16 / 9),
      );
    }

    // placeholder
    return InkWell(
      onTap: _uploading ? null : _pickAndUpload,
      child: Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
        ),
      ),
    );
  }
}

/// ===== 재사용 위젯 =====

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: child,
      ),
    );
  }
}

class _Divider16 extends StatelessWidget {
  const _Divider16();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 16, thickness: 0.8);
}

/// 정보 행(라벨 좌 / 값 우).
/// 값(Text)을 FittedBox로 감싸 화면이 좁아도 **한 줄 유지**하며 자동 축소.
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
        // 라벨
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        // 값: 우측 정렬 + 너비 내에서 자동 축소
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          shadowColor: Colors.black26,
        ),
      ),
    );
  }
}

class _PhotoChangeButton extends StatelessWidget {
  const _PhotoChangeButton({required this.uploading, required this.onPressed});
  final bool uploading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: uploading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.upload),
      label: Text(
        uploading ? '업로드 중...' : '사진 변경',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
