// lib/view/travel_settlement_update_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoen_front/data/dialog/settlement_user_dialog.dart';
import 'package:yoen_front/data/model/payment_create_request.dart'; // Settlement/SettlementParticipant
import 'package:yoen_front/data/model/payment_update_request.dart';
import 'package:yoen_front/data/model/settlement_item.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';

import '../data/enums/status.dart';

class TravelSettlementUpdateScreen extends ConsumerStatefulWidget {
  final int travelId;
  final String paymentType;

  /// PaymentUpdateScreen에서 모은 새 이미지들
  final List<XFile> newImages;

  const TravelSettlementUpdateScreen({
    super.key,
    required this.travelId,
    required this.paymentType,
    required this.newImages,
  });

  @override
  ConsumerState<TravelSettlementUpdateScreen> createState() =>
      _TravelSettlementUpdateScreenState();
}

class _TravelSettlementUpdateScreenState
    extends ConsumerState<TravelSettlementUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _listKey = GlobalKey<AnimatedListState>();

  int _safeParseAmount(String text) {
    if (text.trim().isEmpty) return 0;
    return int.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  Future<void> _save() async {
    final s = ref.read(paymentNotifierProvider);
    final d = s.editDraft;
    if (d == null) return;

    if (!_formKey.currentState!.validate()) return;

    // 각 항목 참여자 체크
    for (final item in d.settlementItems) {
      if (item.travelUserIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('각 정산 항목에 참여 유저를 선택해주세요.')),
        );
        return;
      }
    }

    // SettlementItem -> Settlement
    final settlements = d.settlementItems.map((item) {
      final users = item.travelUserIds.map((uid) {
        final paid = item.settledUserIds.contains(uid);
        return SettlementParticipant(travelUserId: uid, isPaid: paid);
      }).toList();

      return Settlement(
        settlementName: item.nameController.text,
        amount: _safeParseAmount(item.amountController.text),
        travelUsers: users,
      );
    }).toList();

    final total = settlements.fold<int>(0, (sum, s) => sum + s.amount);

    final req = PaymentUpdateRequest(
      paymentId: d.paymentId,
      travelId: widget.travelId,
      paymentType: widget.paymentType,
      paymentName: d.paymentName,
      paymentMethod: d.paymentMethod,
      payerType: d.payerType,
      categoryId: d.categoryId,
      travelUserId: d.travelUserId,
      payTime: d.payTime?.toIso8601String(),
      paymentAccount: total,
      currency: d.currency,
      settlementList: settlements,
      removeImageIds: d.removedImageIds.toList(),
    );

    final files = widget.newImages.map((x) => File(x.path)).toList();

    await ref.read(paymentNotifierProvider.notifier).updatePayment(req, files);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentNotifierProvider, (prev, next) {
      if (next.updateStatus == Status.success) {
        Navigator.of(context).pop(true);
      } else if (next.updateStatus == Status.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '오류가 발생했습니다.')),
        );
      }
    });

    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final state = ref.watch(paymentNotifierProvider);
    final notifier = ref.read(paymentNotifierProvider.notifier);
    final draft = state.editDraft;

    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('정산 항목 수정')),
        body: const Center(child: ProgressBadge(label: "불러오는 중")),
      );
    }

    // 합계 미리보기
    final total = draft.settlementItems
        .map((e) => _safeParseAmount(e.amountController.text))
        .fold<int>(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 항목 수정'),
        actions: [
          if (state.updateStatus == Status.loading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: ProgressBadge(label: "저장 중")),
            )
          else
            IconButton(
              tooltip: '저장',
              onPressed: _save,
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 합계 카드
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color.outlineVariant),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.primary.withOpacity(.1),
                    child: Icon(Icons.summarize, color: color.primary),
                  ),
                  title: Text(
                    '총 정산 금액',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '입력된 항목의 합계입니다.',
                    style: TextStyle(color: color.onSurfaceVariant),
                  ),
                  trailing: Text(
                    _formatCurrency(total, draft.currency),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Form(
                  key: _formKey,
                  child: AnimatedList(
                    key: _listKey,
                    initialItemCount: draft.settlementItems.length,
                    itemBuilder: (context, index, animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        child: _SettlementCard(
                          index: index,
                          item: draft.settlementItems[index],
                          currencyLabel: (draft.currency == 'YEN') ? '엔' : '원',
                          onRemove: draft.settlementItems.length > 1
                              ? () => notifier.removeEditSettlementItem(
                                  index,
                                  _listKey,
                                  (it, anim, i) => SizeTransition(
                                    sizeFactor: anim,
                                    child: _SettlementCard(
                                      index: i,
                                      item: it,
                                      currencyLabel: (draft.currency == 'YEN')
                                          ? '엔'
                                          : '원',
                                      onRemove: null,
                                      onPickUsers: () {},
                                    ),
                                  ),
                                )
                              : null,
                          onPickUsers: () async {
                            final item = draft.settlementItems[index];

                            final initialParticipants =
                                List<SettlementParticipant>.generate(
                                  item.travelUserIds.length,
                                  (i) {
                                    final uid = item.travelUserIds[i];
                                    final name = item.travelUserNames[i];
                                    final paid = item.settledUserIds.contains(
                                      uid,
                                    );
                                    return SettlementParticipant(
                                      travelUserId: uid,
                                      travelNickname: name, // dialog에서 표시용
                                      isPaid: paid, // 사전 정산 여부
                                    );
                                  },
                                );
                            final selected =
                                await showDialog<List<SettlementParticipant>>(
                                  context: context,
                                  builder: (_) => SettlementUserDialog(
                                    travelId: widget.travelId,
                                    initialParticipants: initialParticipants,
                                  ),
                                );
                            if (selected != null) {
                              final ids = selected
                                  .map((e) => e.travelUserId)
                                  .toList();
                              final names = selected
                                  .map((e) => e.travelNickname ?? "")
                                  .toList();
                              notifier.setEditParticipants(
                                index: index,
                                userIds: ids,
                                userNames: names,
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 항목 추가
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => notifier.addEditSettlementItem(_listKey),
                      icon: const Icon(Icons.add),
                      label: const Text('정산 항목 추가'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int value, String? currency) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    final label = (currency == 'YEN') ? '엔' : '원';
    return '$buf $label';
  }
}

class _SettlementCard extends ConsumerStatefulWidget {
  final int index;
  final SettlementItem item;
  final String currencyLabel;
  final VoidCallback? onRemove;
  final VoidCallback onPickUsers;

  const _SettlementCard({
    required this.index,
    required this.item,
    required this.currencyLabel,
    required this.onRemove,
    required this.onPickUsers,
  });

  @override
  ConsumerState<_SettlementCard> createState() => _SettlementCardState();
}

class _SettlementCardState extends ConsumerState<_SettlementCard> {
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final total = widget.item.travelUserIds.length;
    final done = widget.item.settledCount;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '정산 항목 ${widget.index + 1}',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: c.primary.withOpacity(.3)),
                  ),
                  child: Text(
                    '$done/$total',
                    style: t.labelMedium?.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (widget.onRemove != null)
                  IconButton(
                    tooltip: '항목 제거',
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            TextFormField(
              controller: widget.item.nameController,
              decoration: const InputDecoration(
                labelText: '결제 내역 이름',
                hintText: '예) 편의점, 식사, 교통 등',
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? '내역 이름을 입력하세요.' : null,
            ),
            const SizedBox(height: 10),

            TextFormField(
              controller: widget.item.amountController,
              decoration: InputDecoration(
                labelText: '금액',
                hintText: '숫자만 입력',
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    widget.currencyLabel,
                    style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                  ),
                ),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return '금액을 입력하세요.';
                final parsed = int.tryParse(v);
                if (parsed == null || parsed <= 0) return '올바른 금액을 입력하세요.';
                return null;
              },
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.verified_outlined, size: 20),
                const SizedBox(width: 6),
                Text(
                  '정산 현황  ${widget.item.settledCount}/${widget.item.travelUserIds.length}',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (widget.item.allSettled)
                  Icon(Icons.check_circle, color: c.primary),
              ],
            ),
            const SizedBox(height: 8),

            if (widget.item.travelUserIds.isEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '참여 유저를 먼저 선택하세요.',
                  style: t.bodyMedium?.copyWith(color: c.error),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: -6,
                  children: List.generate(widget.item.travelUserIds.length, (
                    i,
                  ) {
                    final uid = widget.item.travelUserIds[i];
                    final name = widget.item.travelUserNames[i];
                    final selected = widget.item.settledUserIds.contains(uid);
                    return FilterChip(
                      label: Text(name),
                      selected: selected,
                      onSelected: (val) {
                        // notifier 호출 없이 로컬 셋만 바꾸면 저장 시 반영 안 됨
                        // → editDraft를 수정하는 토글 API를 쓰는 것이 정석이나
                        //   여기선 간단히 setState로 변경 후 저장 전 DTO 변환하므로 OK.
                        setState(() {
                          if (val) {
                            widget.item.settledUserIds.add(uid);
                          } else {
                            widget.item.settledUserIds.remove(uid);
                          }
                        });
                      },
                      avatar: selected ? const Icon(Icons.done) : null,
                    );
                  }),
                ),
              ),
            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: widget.onPickUsers,
                icon: const Icon(Icons.group_add_outlined),
                label: const Text('참여 유저 선택/변경'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
