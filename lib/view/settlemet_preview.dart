import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:yoen_front/data/model/settlement_payment_type.dart';
import 'package:yoen_front/data/model/settlement_response_user_detail.dart';
import 'package:yoen_front/data/model/settlement_user_details.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';

import '../data/enums/payment_type.dart';
import '../data/model/settlement_preview_params.dart';
import '../data/model/settlement_result_response.dart';
import '../data/notifier/common_provider.dart';
import '../data/notifier/settlement_confirm_controller.dart';

/// 내부에서만 쓰는 간단한 토글 상태
final hidePaidProvider = StateProvider.autoDispose<bool>((ref) => false);

class SettlementPreviewScreen extends ConsumerWidget {
  final SettlementPreviewParams params;
  const SettlementPreviewScreen({super.key, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settlementPreviewProvider(params));
    final confirming = ref.watch(settlementConfirmControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('정산 미리보기')),
      body: async.when(
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 10),
              const ProgressBadge(label: '불러오는 중'),
            ],
          ),
        ),
        error: (e, st) => _ErrorView(
          message: '정산 내역을 불러오지 못했습니다.',
          onRetry: () => ref.refresh(settlementPreviewProvider(params)),
          detail: e.toString(),
        ),
        data: (preview) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(settlementPreviewProvider(params)),
          child: _PreviewBody(preview: preview, params: params),
        ),
      ),
      bottomNavigationBar: async.maybeWhen(
        data: (preview) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: confirming
                  ? null
                  : () async {
                      final lines = _extractSummaryLines(preview);
                      if (lines.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('정산할 항목이 없습니다.')),
                        );
                        return;
                      }
                      final confirmed = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _ConfirmSheet(lines: lines),
                      );
                      if (confirmed == true && context.mounted) {
                        await ref
                            .read(settlementConfirmControllerProvider.notifier)
                            .confirm(params);
                        if (context.mounted) {
                          Navigator.of(context).pop(); // 완료 후 페이지 나가기
                        }
                      }
                    },
              child: confirming
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: ProgressBadge(label: "처리 중"),
                    )
                  : const Text('다음'),
            ),
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _PreviewBody extends ConsumerWidget {
  final SettlementResultResponse preview;
  final SettlementPreviewParams params;
  const _PreviewBody({required this.preview, required this.params});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = preview.userSettlementList;
    final sections = preview.paymentTypeList;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- 정산 요약 ---
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('정산 요약', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (summary.isEmpty)
                  Text(
                    '요약 데이터가 없습니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ...summary.map((g) => _SummaryGroup(group: g)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // --- 타입별 상세 ---
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  dense: true,
                  title: Text('상세 내역', style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    '사전 사용 금액 / 공금 / 기록된 금액',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ...sections
                    // 여기서 params 값에 따라 필터링
                    .where((g) {
                      switch (g.paymentType) {
                        case PaymentType.PREPAYMENT:
                          return params.includePreUseAmount;
                        case PaymentType.SHAREDFUND:
                          return params.includeSharedAmount;
                        case PaymentType.PAYMENT:
                          return params.includeRecordedAmount;
                      }
                    })
                    .map((g) => _TypeSection(group: g)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryGroup extends ConsumerWidget {
  final SettlementResponseUserDetail group;
  const _SummaryGroup({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hidePaid = ref.watch(hidePaidProvider);

    final items = group.userSettlementList
        .where((u) => (u.amount ?? 0) > 0)
        .where((u) => !hidePaid || u.isPaid != true)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          group.receiverNickname,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '내역 없음',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ...items.map(
          (u) => _buildTransferRow(
            context: context,
            leftText: '${u.senderNickname} → ${group.receiverNickname}',
            amount: u.amount ?? 0,
            isPaid: u.isPaid == true,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _TypeSection extends ConsumerWidget {
  final SettlementPaymentType group;
  const _TypeSection({required this.group});

  String get _header {
    switch (group.paymentType) {
      case PaymentType.PREPAYMENT:
        return '사전 사용 금액';
      case PaymentType.PAYMENT:
        return '기록된 금액';
      case PaymentType.SHAREDFUND:
        return '공금';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hidePaid = ref.watch(hidePaidProvider);

    final receivers =
        group.settlementList ?? const <SettlementResponseUserDetail>[];

    // 1) 동일 receiverNickname끼리 병합
    final Map<String, List<SettlementUserDetails>> byReceiver = {};
    for (final r in receivers) {
      final key = r.receiverNickname;
      final list = r.userSettlementList ?? const <SettlementUserDetails>[];
      (byReceiver[key] ??= []).addAll(list);
    }

    // 2) 완료 숨김/0원 제거 필터 적용
    final mergedReceivers = byReceiver.entries
        .map((e) {
          final filtered = e.value
              .where((u) => (u.amount ?? 0) > 0)
              .where((u) => !hidePaid || u.isPaid != true)
              .toList();
          return _ReceiverView(receiverNickname: e.key, items: filtered);
        })
        .where((rv) => rv.items.isNotEmpty)
        .toList();

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(_header, style: theme.textTheme.titleMedium),
        children: mergedReceivers.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hidePaid ? '표시할 미완료 내역이 없습니다.' : '내역 없음',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ]
            : mergedReceivers
                  .map((rv) => _ReceiverBlockMerged(view: rv))
                  .toList(growable: false),
      ),
    );
  }
}

/// UI용 병합 모델
class _ReceiverView {
  final String receiverNickname;
  final List<SettlementUserDetails> items;
  _ReceiverView({required this.receiverNickname, required this.items});
}

class _ReceiverBlockMerged extends StatelessWidget {
  final _ReceiverView view;
  const _ReceiverBlockMerged({required this.view});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    // 1) paymentId 기준 그룹핑
    final Map<int, List<SettlementUserDetails>> byPaymentId = {};
    for (final u in view.items) {
      final pid = u.paymentId ?? -1;
      (byPaymentId[pid] ??= []).add(u);
    }
    if (byPaymentId.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        ListTile(
          dense: true,
          title: Text(view.receiverNickname, style: theme.textTheme.labelLarge),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: byPaymentId.entries.map((entry) {
              final paymentItems = entry.value;
              final first = paymentItems.first;

              final paymentName = (first.paymentName ?? '').isNotEmpty
                  ? first.paymentName!
                  : '-';

              DateTime? headerTime;
              for (final u in paymentItems) {
                final dt = (u.payTime != null)
                    ? DateTime.tryParse(u.payTime!)
                    : null;
                if (dt != null) {
                  headerTime = (headerTime == null || dt.isBefore(headerTime!))
                      ? dt
                      : headerTime;
                }
              }
              final timeStr = headerTime != null
                  ? DateFormat('yyyy.MM.dd HH:mm').format(headerTime!)
                  : '-';

              // settlementName 기준으로 children 나누기
              final Map<String, List<SettlementUserDetails>> bySettlement = {};
              for (final u in paymentItems) {
                final sname = (u.settlementName ?? '').isNotEmpty
                    ? u.settlementName!
                    : '-';
                (bySettlement[sname] ??= []).add(u);
              }

              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Payment 헤더 (한 번만) ===
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.receipt_long, size: 18, color: c.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // paymentName: 위계 가장 높게
                              Text(
                                paymentName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                timeStr,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: c.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // === settlementName 섹션들 (여러 개) ===
                    ...bySettlement.entries.map((se) {
                      final settlementName = se.key;
                      final lines = se.value
                          .map(
                            (u) => _GroupedLine(
                              leftText: u.senderNickname ?? '-',
                              amount: u.amount ?? 0,
                              isPaid: u.isPaid == true,
                            ),
                          )
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          top: 10,
                          bottom: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 소제목: settlementName (작고, 보조색, 위계 낮춤 + 간격 확보)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.event_note, size: 14),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    settlementName,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: c.onSurfaceVariant,
                                    ),
                                    softWrap: true,
                                    overflow: TextOverflow.visible,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // 송금 라인들
                            ...lines.map(
                              (l) => _buildTransferRow(
                                context: context,
                                leftText: l.leftText,
                                amount: l.amount,
                                isPaid: l.isPaid,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final String? detail;
  const _ErrorView({required this.message, required this.onRetry, this.detail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(detail!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

String _money(num v) => NumberFormat.decimalPattern('ko_KR').format(v);

/// 체크리스트 라인 모델
class _Line {
  final String sender;
  final String receiver;
  final int amount;
  final bool isPaid;

  const _Line({
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.isPaid,
  });
}

/// 프리뷰 응답에서 summary(userSettlementList)만 추출
List<_Line> _extractSummaryLines(SettlementResultResponse preview) {
  final out = <_Line>[];
  final groups = preview.userSettlementList ?? const [];

  for (final g in groups) {
    final receiver = g.receiverNickname;
    for (final u in g.userSettlementList ?? const <SettlementUserDetails>[]) {
      final sender = u.senderNickname ?? '';
      final amount = (u.amount ?? 0);
      if (sender.isEmpty || receiver.isEmpty) continue;
      if (amount <= 0) continue;

      out.add(
        _Line(
          sender: sender,
          receiver: receiver,
          amount: amount,
          isPaid: u.isPaid == true,
        ),
      );
    }
  }
  return out;
}

class _ConfirmSheet extends StatefulWidget {
  final List<_Line> lines;
  const _ConfirmSheet({required this.lines});

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  late final List<bool> checks = List<bool>.filled(widget.lines.length, true);
  bool sentAll = false;
  bool get allChecked => checks.every((e) => e) && sentAll;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final txt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '정산하기',
                  style: txt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shrinkWrap: true,
                itemCount: widget.lines.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final l = widget.lines[i];
                  return CheckboxListTile(
                    value: checks[i],
                    onChanged: (v) => setState(() => checks[i] = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: RichText(
                      text: TextSpan(
                        style: txt.bodyLarge?.copyWith(
                          color: txt.bodyLarge?.color,
                        ),
                        children: [
                          TextSpan(text: '${l.sender} → ${l.receiver}  '),
                          TextSpan(
                            text:
                                '${NumberFormat.decimalPattern('ko_KR').format(l.amount)}원',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Text(
                '정산완료를 선택하셨습니다.\n정산을 완료하면 지금까지 기록된 금액들에 대하여 모두 정산 완료 처리됩니다.\n정산금 미리보기에 표시된 금액을 모두 송금하셨습니까?',
                style: txt.bodySmall?.copyWith(color: c.onSurfaceVariant),
              ),
            ),
            CheckboxListTile(
              value: sentAll,
              onChanged: (v) => setState(() => sentAll = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('네 송금했습니다'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: FilledButton(
                onPressed: allChecked
                    ? () => Navigator.of(context).pop(true)
                    : null,
                child: const Text('정산 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTransferRow({
  required BuildContext context,
  required String leftText,
  required int amount,
  required bool isPaid,
}) {
  final theme = Theme.of(context);
  final c = theme.colorScheme;

  final icon = isPaid
      ? Icons.check_circle_rounded
      : Icons.radio_button_unchecked;
  final iconColor = isPaid ? c.primary : c.outline;

  final amountStyle = theme.textTheme.bodySmall?.copyWith(
    fontWeight: FontWeight.w700,
    decoration: isPaid ? TextDecoration.lineThrough : null,
    color: isPaid ? c.onSurfaceVariant : theme.textTheme.bodySmall?.color,
  );

  final leftStyle = theme.textTheme.bodySmall?.copyWith(
    color: isPaid ? c.onSurfaceVariant : theme.textTheme.bodySmall?.color,
  );

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                leftText,
                style: leftStyle,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
        Text('${_money(amount)}원', style: amountStyle),
      ],
    ),
  );
}

class _GroupedLine {
  final String leftText;
  final int amount;
  final bool isPaid;
  _GroupedLine({
    required this.leftText,
    required this.amount,
    required this.isPaid,
  });
}
