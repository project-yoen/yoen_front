import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yoen_front/data/dialog/settlement_user_dialog.dart';
import 'package:yoen_front/data/model/payment_create_request.dart'; // PaymentRequest/Settlement/SettlementParticipant
import 'package:yoen_front/data/model/settlement_item.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/payment_create_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';

class TravelSettlementCreateScreen extends ConsumerStatefulWidget {
  final int travelId;
  final String paymentType;

  /// 상위에서 고정 통화 전달: 'YEN' 또는 'WON'
  final String currencyCode;

  const TravelSettlementCreateScreen({
    super.key,
    required this.travelId,
    required this.paymentType,
    required this.currencyCode, // 'YEN' | 'WON'
  });

  @override
  ConsumerState<TravelSettlementCreateScreen> createState() =>
      _TravelSettlementCreateScreenState();
}

class _TravelSettlementCreateScreenState
    extends ConsumerState<TravelSettlementCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _listKey = GlobalKey<AnimatedListState>();

  String get _currencyLabel => widget.currencyCode == 'YEN' ? '엔' : '원';

  int _safeParseAmount(String text) {
    if (text.trim().isEmpty) return 0;
    return int.tryParse(text.replaceAll(',', '')) ?? 0;
  }

  Future<void> _savePayment(
    PaymentCreateState state,
    PaymentCreateNotifier notifier,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    // 각 항목 참여자 체크
    for (final item in state.settlementItems) {
      if (item.travelUserIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('각 정산 항목에 참여 유저를 선택해주세요.')),
        );
        return;
      }
    }

    // ✅ 사람 기준 participants 생성
    final settlementList = state.settlementItems.map((item) {
      final participants = item.travelUserIds.map((uid) {
        final paid = item.settledUserIds.contains(uid);
        return SettlementParticipant(travelUserId: uid, isPaid: paid);
      }).toList();

      return Settlement(
        settlementName: item.nameController.text,
        amount: _safeParseAmount(item.amountController.text),
        travelUsers: participants,
      );
    }).toList();

    final totalAmount = settlementList.fold<int>(0, (sum, s) => sum + s.amount);

    final request = PaymentRequest(
      paymentId: null, // 수정 모드면 여기에 기존 paymentId 세팅
      travelId: widget.travelId,
      travelUserId: state.payerTravelUserId,
      categoryId: state.categoryId!,
      payerType: state.payerType!,
      payTime: state.payTime!.toIso8601String(),
      paymentName: state.paymentName!,
      paymentMethod: state.paymentMethod!,
      paymentType: widget.paymentType,
      paymentAccount: totalAmount,
      currency: widget.currencyCode,
      settlementList: settlementList,
    );

    final imageFiles = state.images.map((x) => File(x.path)).toList();

    await ref
        .read(paymentNotifierProvider.notifier)
        .createPayment(request, imageFiles);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentNotifierProvider, (previous, next) {
      if (next.createStatus == Status.success) {
        Navigator.of(context).pop(true);
      } else if (next.createStatus == Status.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '오류가 발생했습니다.')),
        );
      }
    });

    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final state = ref.watch(paymentCreateNotifierProvider);
    final notifier = ref.read(paymentCreateNotifierProvider.notifier);
    final paymentState = ref.watch(paymentNotifierProvider);

    // 합계 미리보기
    final total = state.settlementItems
        .map((e) => _safeParseAmount(e.amountController.text))
        .fold<int>(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 내역 추가'),
        actions: [
          if (paymentState.createStatus == Status.loading)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: ProgressBadge(label: "저장 중")),
            )
          else
            IconButton(
              tooltip: '저장',
              onPressed: () => _savePayment(state, notifier),
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
                    '${_formatCurrency(total)} $_currencyLabel',
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
                    initialItemCount: state.settlementItems.length,
                    itemBuilder: (context, index, animation) {
                      return SizeTransition(
                        sizeFactor: animation,
                        child: _SettlementCard(
                          index: index,
                          item: state.settlementItems[index],
                          currencyLabel: _currencyLabel, // 표시에만 사용
                          onRemove: state.settlementItems.length > 1
                              ? () => notifier.removeSettlementItem(
                                  index,
                                  _listKey,
                                  (it, anim, i) => SizeTransition(
                                    sizeFactor: anim,
                                    child: _SettlementCard(
                                      index: i,
                                      item: it,
                                      currencyLabel: _currencyLabel,
                                      onRemove: null,
                                      onPickUsers: () {},
                                    ),
                                  ),
                                )
                              : null,
                          onPickUsers: () async {
                            // 현재 선택된 유저들로 DTO 리스트 생성
                            final currentParticipants = state
                                .settlementItems[index]
                                .travelUserIds
                                .asMap()
                                .entries
                                .map((entry) {
                                  final id = entry.value;
                                  final name = state
                                      .settlementItems[index]
                                      .travelUserNames[entry.key];
                                  return SettlementParticipant(
                                    travelUserId: id,
                                    travelNickname: name,
                                    isPaid: state
                                        .settlementItems[index]
                                        .settledUserIds
                                        .contains(id),
                                  );
                                })
                                .toList();

                            final selected =
                                await showDialog<List<SettlementParticipant>>(
                                  context: context,
                                  builder: (_) => SettlementUserDialog(
                                    travelId: widget.travelId,
                                    initialParticipants: currentParticipants,
                                  ),
                                );
                            if (selected != null) {
                              setState(() {
                                final ids = selected
                                    .map((e) => e.travelUserId)
                                    .toList();
                                final names = selected
                                    .map((e) => e.travelNickname ?? "")
                                    .toList();

                                // 참여자 갱신 + 기존 정산완료 집합 정리(없는 사람 제거)
                                final item = state.settlementItems[index];
                                item.travelUserIds = ids;
                                item.travelUserNames = names;
                                item.settledUserIds = item.settledUserIds
                                    .intersection(ids.toSet());
                              });
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
                      onPressed: () => notifier.addSettlementItem(_listKey),
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

  String _formatCurrency(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}

/// 항목 카드(통화 선택 UI 제거, 표시에만 라벨 사용 + 사람별 정산 토글)
class _SettlementCard extends StatefulWidget {
  final int index;
  final SettlementItem item;

  /// 화면 표시용 '엔' | '원'
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
  State<_SettlementCard> createState() => _SettlementCardState();
}

class _SettlementCardState extends State<_SettlementCard> {
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
            // 헤더
            Row(
              children: [
                Text(
                  '정산 항목 ${widget.index + 1}',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                // 진행도 배지
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

            // 내역 이름
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

            // 금액 (통화 라벨만 표시)
            TextFormField(
              controller: widget.item.amountController,
              decoration: InputDecoration(
                labelText: '금액',
                hintText: '숫자만 입력',
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    widget.currencyLabel, // '엔' 또는 '원'
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

            // ✅ 사람 기준 정산 현황
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

            // 참여자별 완료 토글(FilterChip)
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

            // 참여 유저 선택 버튼
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
