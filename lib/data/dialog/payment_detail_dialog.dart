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
      final dt = DateTime.parse(iso);
      final local = dt.isUtc ? dt.toLocal() : dt;
      return DateFormat('yyyy.MM.dd (E) a h:mm', 'ko_KR').format(local);
    } catch (_) {
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

        final currencyCode = (detail.currency ?? 'WON').toUpperCase();
        final currencyLabel = currencyCode == 'YEN' ? '엔' : '원';

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

              // 정산 정보 (참여자별 isPaid 반영)
              _sectionTitle('정산 정보', t),
              if (detail.settlements != null && detail.settlements!.isNotEmpty)
                ...detail.settlements!.map((settlement) {
                  final users = settlement.travelUsers; // List<...> (isPaid 포함)
                  final total = users.length;
                  final paidCount = users.where(_userPaid).length;
                  final allPaid = total > 0 && paidCount == total;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 제목 + 진행도 배지
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                settlement.settlementName,
                                style: t.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: allPaid
                                    ? c.primary.withOpacity(.1)
                                    : c.error.withOpacity(.08),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: allPaid
                                      ? c.primary.withOpacity(.3)
                                      : c.error.withOpacity(.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    allPaid
                                        ? Icons.check_circle
                                        : Icons.error_outline,
                                    size: 16,
                                    color: allPaid ? c.primary : c.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$paidCount/$total',
                                    style: t.labelMedium?.copyWith(
                                      color: allPaid ? c.primary : c.error,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // 금액
                        Text(
                          '금액: ${NumberFormat('#,###').format(settlement.amount)}$currencyLabel',
                          style: t.bodySmall,
                        ),

                        const SizedBox(height: 6),

                        // 참여자별 정산 여부(읽기 전용)
                        if (users.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: -6,
                            children: users.map((u) {
                              final paid = _userPaid(u);
                              final name = (u.travelNickname ?? '')
                                  .toString()
                                  .trim();
                              return FilterChip(
                                label: Text(name.isEmpty ? '-' : name),
                                selected: paid,
                                onSelected: null, // 읽기 전용
                                avatar: paid
                                    ? const Icon(Icons.done, size: 18)
                                    : null,
                              );
                            }).toList(),
                          )
                        else
                          Text(
                            '대상자 없음',
                            style: t.bodySmall?.copyWith(
                              color: c.onSurfaceVariant,
                            ),
                          ),

                        // 미정산자 목록
                        if (users.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Builder(
                            builder: (_) {
                              final unpaidNames = users
                                  .where((u) => !_userPaid(u))
                                  .map((u) => u.travelNickname)
                                  .whereType<String>()
                                  .toList();
                              if (unpaidNames.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                '미정산: ${unpaidNames.join(', ')}',
                                style: t.bodySmall?.copyWith(color: c.error),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                })
              else
                Text(
                  '정산 내역이 없습니다.',
                  style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                ),

              const SizedBox(height: 16),

              // 영수증/사진
              if (images.isNotEmpty) ...[
                _sectionTitle('영수증/사진', t),
                const SizedBox(height: 8),
                _imageGrid(images, context),
              ],
            ],
          ),
        );

      default:
        return const SizedBox();
    }
  }

  // ---- 참여자 isPaid 안전 판독 ----
  bool _userPaid(dynamic user) {
    try {
      final v = (user as dynamic).isPaid;
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v.toLowerCase() == 'true';
    } catch (_) {}
    return false;
  }

  // 이미지 썸네일 그리드
  Widget _imageGrid(List<dynamic> images, BuildContext context) {
    const spacing = 8.0;
    final maxWidth = MediaQuery.of(context).size.width - 48; // 좌우 24px 여백 가정
    const minItem = 100.0;
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

  String _imageUrlOf(dynamic img) {
    try {
      if (img == null) return '';
      if (img is String) return img;
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
