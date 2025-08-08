// lib/ui/items/payment_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/payment_response.dart';

typedef PaymentMenuAction = Future<void> Function(String action);

class PaymentTile extends StatelessWidget {
  final PaymentResponse payment;
  final VoidCallback onTap;
  final PaymentMenuAction? onMenuAction;

  const PaymentTile({
    super.key,
    required this.payment,
    required this.onTap,
    this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final paymentTime = DateTime.parse(payment.payTime);
    final formattedTime = DateFormat('a h:mm', 'ko_KR').format(paymentTime);

    final currencyCode = (payment.currency ?? 'WON').toUpperCase();
    final currencyLabel = currencyCode == 'YEN' ? '엔' : '원';
    final formattedAmount = NumberFormat(
      '#,###',
    ).format(payment.paymentAccount);
    final amountDisplay = '$formattedAmount$currencyLabel';

    final payerTypeLabel = _payerTypeLabel(payment.payerType);
    final categoryLabel = payment.categoryName;
    final payer = payment.payer;

    Offset? tapPosition;

    return GestureDetector(
      onTapDown: (d) => tapPosition = d.globalPosition,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenuAction == null
            ? null
            : () async {
                if (tapPosition == null) return;
                final overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                final result = await showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    tapPosition!.dx,
                    tapPosition!.dy,
                    overlay.size.width - tapPosition!.dx,
                    overlay.size.height - tapPosition!.dy,
                  ),
                  items: const [
                    PopupMenuItem(value: 'edit', child: Text('수정')),
                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                );
                if (result != null) await onMenuAction!(result);
              },
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단
                Row(
                  children: [
                    _payerTypeIcon(payment.payerType, c),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        payment.paymentName,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _timePill(formattedTime, c, t),
                  ],
                ),

                const SizedBox(height: 4),

                // 결제자
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: c.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '결제자: $payer',
                        style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // 칩: payerType + 카테고리
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: -6,
                  children: [
                    _chip(payerTypeLabel, c, filled: false),
                    if (categoryLabel != null && categoryLabel.isNotEmpty)
                      _chip(categoryLabel, c, filled: false),
                  ],
                ),

                const SizedBox(height: 6),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    amountDisplay,
                    style: t.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: payment.paymentType == 'SHAREDFUND'
                          ? Colors
                                .blueAccent // 공금 채우기만 색 변경
                          : payment.payerType == 'SHAREDFUND'
                          ? Colors.redAccent
                          : c.onSurface, // 나머지는 기본 글자색
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _payerTypeLabel(String? payerType) {
    switch (payerType) {
      case 'SHAREDFUND':
        return '공금 결제';
      case 'INDIVIDUAL':
      default:
        return '개인 결제';
    }
  }

  Widget _payerTypeIcon(String? payerType, ColorScheme c) {
    final isSharedPay = payerType == 'SHAREDFUND';
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isSharedPay
            ? c.primary.withOpacity(.15)
            : c.surfaceVariant.withOpacity(.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isSharedPay ? Icons.groups_outlined : Icons.person_outline,
        size: 18,
        color: c.onSurface,
      ),
    );
  }

  Widget _timePill(String text, ColorScheme c, TextTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Text(
        text,
        style: t.labelSmall?.copyWith(color: c.onSurfaceVariant),
      ),
    );
  }

  Widget _chip(String label, ColorScheme c, {bool filled = false}) {
    final bg = filled ? c.primary.withOpacity(.10) : c.primary.withOpacity(.08);
    final bd = filled ? c.primary.withOpacity(.40) : c.primary.withOpacity(.25);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bd),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c.primary,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
