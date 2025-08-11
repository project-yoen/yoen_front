import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/settlement_response.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';

import '../../view/image_preview.dart';
import '../../view/payment_update.dart';
import '../../view/travel_sharedfund_update.dart';
import '../notifier/overview_notifier.dart';
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
  bool _showMeta = false; // 결제수단/환율/시간 토글

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

  String _mapPaymentMethod(String? code) {
    switch ((code ?? '').toUpperCase()) {
      case 'CASH':
        return '현금';
      case 'CARD':
        return '카드';
      case 'TRAVELCARD':
        return '트레블카드';
      default:
        return code ?? '-';
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
      content: ConstrainedBox(
        // 폭 제한 변경
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          minWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: _buildContent(state, context),
      ),
      actions: [
        if (state.getDetailsStatus == Status.success &&
            state.selectedPayment != null &&
            state.selectedPayment!.travelId != null &&
            state.selectedPayment!.paymentType != null)
          FilledButton.icon(
            icon: const Icon(Icons.edit_outlined),
            label: const Text('수정'),
            onPressed: () async {
              final detail = ref.read(paymentNotifierProvider).selectedPayment!;
              final type = (detail.paymentType ?? '').toUpperCase();

              // paymentType에 따라 다른 수정 화면으로 분기
              final route = (type == 'SHAREDFUND')
                  ? MaterialPageRoute<bool>(
                      builder: (_) => TravelSharedfundUpdateScreen(
                        paymentId: widget.paymentId,
                        travelId: detail.travelId!,
                      ),
                    )
                  : MaterialPageRoute<bool>(
                      builder: (_) => PaymentUpdateScreen(
                        paymentId: widget.paymentId,
                        travelId: detail.travelId!,
                        paymentType: type, // 'PAYMENT' 등
                      ),
                    );

              final saved = await Navigator.of(context).push<bool>(route);

              if (saved == true && mounted) {
                // 마지막 조회 컨텍스트로 새로고침
                await ref.read(overviewNotifierProvider.notifier).refreshLast();
              }
            },
          ),
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
              // 결제 정보(핵심만 항상 표시)
              _sectionTitle('결제 정보', t),
              _infoRow('결제자', detail.payerName?.travelNickname ?? '-'),
              _infoRow(
                '금액',
                '${NumberFormat('#,###').format(detail.paymentAccount)}$currencyLabel',
              ),
              _infoRow('카테고리', detail.categoryName ?? '-'),

              const SizedBox(height: 8),

              // 추가 정보 토글 (결제수단/환율/시간)
              InkWell(
                onTap: () => setState(() => _showMeta = !_showMeta),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showMeta ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: c.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showMeta ? '추가 정보 접기' : '추가 정보 보기',
                        style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                child: !_showMeta
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          children: [
                            _infoRow(
                              '결제수단',
                              _mapPaymentMethod(detail.paymentMethod),
                            ),
                            _infoRow(
                              '환율',
                              detail.exchangeRate != null
                                  ? NumberFormat(
                                      '#,###.##',
                                    ).format(detail.exchangeRate!)
                                  : '-',
                            ),
                            _infoRow('시간', _formatPayTime(detail.payTime)),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // 정산 정보
              _sectionTitle('정산 정보', t),
              if (detail.settlements != null && detail.settlements!.isNotEmpty)
                ...detail.settlements!.map(
                  (settlement) => _buildSettlementCompact(
                    context: context,
                    settlement: settlement,
                    currencyLabel: currencyLabel,
                  ),
                )
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

  /// SettlementResponse 기반 콤팩트 카드
  Widget _buildSettlementCompact({
    required BuildContext context,
    required SettlementResponse settlement,
    required String currencyLabel,
  }) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final users = settlement.travelUsers;
    final total = users.length;
    final paidUsers = users.where((u) => u.isPaid).toList();
    final unpaidUsers = users.where((u) => !u.isPaid).toList();

    bool showPaid = false;

    return StatefulBuilder(
      builder: (ctx, setStateSB) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
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
                  const SizedBox(width: 8),
                  Text(
                    '${NumberFormat('#,###').format(settlement.amount)}$currencyLabel',
                    style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${paidUsers.length}/$total',
                      style: t.labelSmall?.copyWith(
                        color: c.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 미정산자
              if (unpaidUsers.isNotEmpty) ...[
                _miniLabel('미정산', c, t),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: -6,
                  children: unpaidUsers
                      .map(
                        (u) => _pill(
                          u.travelNickname ?? '-',
                          borderColor: c.outlineVariant,
                        ),
                      )
                      .toList(),
                ),
              ] else
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: c.primary),
                    const SizedBox(width: 6),
                    Text(
                      '모두 정산 완료',
                      style: t.bodySmall?.copyWith(color: c.primary),
                    ),
                  ],
                ),

              // 정산 완료자
              if (paidUsers.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => setStateSB(() => showPaid = !showPaid),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          showPaid ? Icons.expand_less : Icons.expand_more,
                          size: 18,
                          color: c.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '정산 완료 ${paidUsers.length}명 보기',
                          style: t.bodySmall?.copyWith(
                            color: c.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 140),
                  child: !showPaid
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: -6,
                            children: paidUsers
                                .map(
                                  (u) => _pill(
                                    u.travelNickname ?? '-',
                                    fillColor: c.surfaceVariant,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _miniLabel(String text, ColorScheme c, TextTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: t.labelSmall?.copyWith(color: c.onSurfaceVariant),
      ),
    );
  }

  Widget _pill(String text, {Color? fillColor, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: fillColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor ?? Colors.transparent),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _imageGrid(List<dynamic> images, BuildContext context) {
    const spacing = 8.0;

    // Dialog의 가용 폭 기반으로 한 줄 개수 계산
    final maxWidth = MediaQuery.of(context).size.width - 48;
    const minItem = 100.0;
    final crossAxisCount = (maxWidth / (minItem + spacing)).floor().clamp(1, 6);
    final itemSize =
        (maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

    // 안전한 URL 리스트 생성
    final urls = images
        .map((img) => _imageUrlOf(img).trim())
        .where((u) => u.isNotEmpty)
        .toList();

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(urls.length, (index) {
        final url = urls[index];
        return SizedBox(
          width: itemSize,
          child: InkWell(
            onTap: () {
              // ✅ RecordDetailDialog와 동일한 프리뷰 라우팅
              context.pushTransparentRoute(
                ImagePreviewPage(imageUrls: urls, initialIndex: index),
              );
            },
            child: ExcludeSemantics(
              child: ResponsiveShimmerImage(
                imageUrl: url,
                aspectRatio: 1.0,
                borderRadius: 8,
              ),
            ),
          ),
        );
      }),
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

  // 날짜 잘림 방지를 위해 value는 줄바꿈 허용 + 여유 라인
  Widget _infoRow(String label, String value) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 6),
          // 줄바꿈 허용
          Expanded(
            child: Text(
              value,
              style: t.bodyMedium,
              softWrap: true,
              maxLines: 3, // 필요시 더 늘려도 됨
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }
}
