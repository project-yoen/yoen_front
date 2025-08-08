import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/payment_detail_response.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';

import '../widget/progress_badge.dart';
import '../widget/responsive_shimmer_image.dart';

class PaymentDetailDialog extends ConsumerStatefulWidget {
  final int paymentId;

  const PaymentDetailDialog({super.key, required this.paymentId});

  @override
  ConsumerState<PaymentDetailDialog> createState() =>
      _PaymentDetailDialogState();
}

class _PaymentDetailDialogState extends ConsumerState<PaymentDetailDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(paymentNotifierProvider.notifier)
          .getPaymentDetails(widget.paymentId),
    );
  }

  String _formatPayTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      // ISO8601 문자열 파싱
      final dt = DateTime.parse(iso);

      // 서버가 UTC(Z)로 내려줄 수 있으니 로컬로 변환
      final local = dt.isUtc ? dt.toLocal() : dt;

      // 예: 2025.08.05 (화) 오후 3:27
      return DateFormat('yyyy.MM.dd (E) a h:mm', 'ko_KR').format(local);
    } catch (_) {
      // 혹시 형식이 예상과 달라도 앱이 죽지 않게 안전하게 처리
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentNotifierProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        state.selectedPayment?.paymentName ?? '결제 상세',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: _buildContent(state, context),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  Widget _buildContent(PaymentState state, BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    switch (state.getDetailsStatus) {
      case Status.loading:
        return SizedBox(
          height: 100,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: c.primary),
                const SizedBox(height: 8),
                ProgressBadge(label: "불러오는 중"),
              ],
            ),
          ),
        );

      case Status.error:
        return Text(
          '오류: ${state.errorMessage}',
          style: const TextStyle(color: Colors.red),
        );

      case Status.success:
        final detail = state.selectedPayment;
        if (detail == null) {
          return const Text('상세 정보를 불러올 수 없습니다.');
        }

        // 통화코드 -> 엔/원 변환
        final currencyCode = (detail.currency ?? 'WON').toUpperCase();
        final currencyLabel = currencyCode == 'YEN' ? '엔' : '원';

        // 이미지 리스트 안전하게 잡기
        final images = (detail.images ?? [])
            .where((img) => _imageUrlOf(img).isNotEmpty)
            .toList();

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 결제 정보
              _sectionTitle('결제 정보', t),
              _infoRow('결제자', detail.payerName?.travelNickName ?? '-'),
              _infoRow(
                '금액',
                '${NumberFormat('#,###').format(detail.paymentAccount)}$currencyLabel',
              ),
              _infoRow('카테고리', detail.categoryName ?? '-'),
              _infoRow('결제수단', detail.paymentMethod ?? '-'),
              _infoRow(
                '환율',
                detail.exchangeRate != null
                    ? NumberFormat('#,###.##').format(detail.exchangeRate!)
                    : '-',
              ),
              _infoRow('시간', _formatPayTime(detail.payTime)),

              const SizedBox(height: 16),

              // 정산 정보
              _sectionTitle('정산 정보', t),
              if (detail.settlements != null && detail.settlements!.isNotEmpty)
                ...detail.settlements!.map(
                  (settlement) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settlement.settlementName,
                          style: t.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '금액: ${NumberFormat('#,###').format(settlement.amount)}$currencyLabel',
                          style: t.bodySmall,
                        ),
                        Text(
                          '정산 여부: ${settlement.isPaid ? '완료' : '미완료'}',
                          style: t.bodySmall,
                        ),
                        if (settlement.travelUsers.isNotEmpty)
                          Text(
                            '대상자: ${settlement.travelUsers.map((u) => u.travelNickName).join(', ')}',
                            style: t.bodySmall?.copyWith(
                              color: c.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  '정산 내역이 없습니다.',
                  style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                ),
              // --- 정산 정보 블록 끝난 직후에 추가 ---
              const SizedBox(height: 16),
              if (images.isNotEmpty) ...[
                _sectionTitle('영수증/사진', t),
                const SizedBox(height: 8),
                _imageGrid(images, context), // 맨 아래로 이동
              ],
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  // 이미지 썸네일 그리드
  // 1) content 빌드 그대로 두고,
  // 2) _imageGrid 만 교체
  Widget _imageGrid(List<dynamic> images, BuildContext context) {
    const spacing = 8.0;

    // Dialog의 가용 폭 기반으로 한 줄에 몇 개 넣을지 계산
    final maxWidth = MediaQuery.of(context).size.width - 48; // 좌우 24px 여백 가정
    const minItem = 100.0; // 최소 썸네일 폭
    final crossAxisCount = (maxWidth / (minItem + spacing)).floor().clamp(1, 6);
    final itemSize =
        (maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: images.map((img) {
        final url = _imageUrlOf(img).trim();
        if (url.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          width: itemSize,
          // 정사각형 썸네일: aspectRatio 1.0로 맞춤
          child: InkWell(
            onTap: () => _openImageViewer(context, url),
            child: ExcludeSemantics(
              child: ResponsiveShimmerImage(
                imageUrl: url,
                aspectRatio: 1.0,
                borderRadius: 8,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // 단일 이미지 확대 뷰어
  void _openImageViewer(BuildContext context, String url) {
    if (url.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.85),
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white70,
                  size: 48,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 이미지 URL 안전 추출 (모델 구현별 key 차이 흡수)
  String _imageUrlOf(dynamic img) {
    // 예상 가능한 키들 우선순위로 검사
    try {
      // e.g. PaymentImage(imageUrl), ImageResponse(url), etc.
      if (img == null) return '';
      if (img is String) return img; // 이미 url 문자열인 경우
      if ((img as dynamic).imageUrl != null) {
        return (img as dynamic).imageUrl as String;
      }
      if ((img as dynamic).url != null) return (img as dynamic).url as String;
      if ((img as dynamic).path != null) return (img as dynamic).path as String;
    } catch (_) {}
    return '';
  }

  Widget _sectionTitle(String title, TextTheme t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: t.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
