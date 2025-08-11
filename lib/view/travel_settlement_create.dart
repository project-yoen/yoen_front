import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:yoen_front/data/dialog/settlement_user_dialog.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
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

    // currency는 화면 파라미터(widget.currencyCode)로 고정
    final settlementList = state.settlementItems.map((item) {
      final travelUsersDto = item.travelUserIds
          .map(
            (id) => SettlementParticipantRequestDto(
              travelUserId: id,
              isPaid: item.isPaid, // 각 항목의 정산 여부를 개별 유저에게 적용
            ),
          )
          .toList();

      return Settlement(
        settlementName: item.nameController.text,
        amount: _safeParseAmount(item.amountController.text),
        isPaid: item.isPaid,
        travelUsers: travelUsersDto,
      );
    }).toList();

    final totalAmount = settlementList.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );

    final request = PaymentCreateRequest(
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
                                  return SettlementParticipantDto(
                                    travelUserId: id,
                                    travelNickName: name,
                                    isPaid: state.settlementItems[index].isPaid,
                                  );
                                })
                                .toList();

                            final selected =
                                await showDialog<
                                  List<SettlementParticipantDto>
                                >(
                                  context: context,
                                  builder: (_) => SettlementUserDialog(
                                    travelId: widget.travelId,
                                    initialParticipants: currentParticipants,
                                    showPaidCheckBox:
                                        false, // 일반 정산에서는 사전 정산 체크박스 미표시
                                  ),
                                );
                            if (selected != null) {
                              setState(() {
                                final ids = selected
                                    .map((e) => e.travelUserId)
                                    .toList();
                                final names = selected
                                    .map((e) => e.travelNickName)
                                    .toList();
                                state.settlementItems[index].travelUserIds =
                                    ids;
                                state.settlementItems[index].travelUserNames =
                                    names;
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

/// 항목 카드(통화 선택 UI 제거, 표시에만 라벨 사용)
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
  late bool _isPaid;

  @override
  void initState() {
    super.initState();
    _isPaid = widget.item.isPaid;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

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
            const SizedBox(height: 6),

            // 정산 여부
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('정산 여부'),
              value: _isPaid,
              onChanged: (val) {
                setState(() {
                  _isPaid = val;
                  widget.item.isPaid = val;
                });
              },
              secondary: const Icon(Icons.verified_outlined),
            ),

            // 참여 유저
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onPickUsers,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '참여 유저',
                      style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    if (widget.item.travelUserNames.isEmpty)
                      Text(
                        '선택되지 않음',
                        style: t.bodyMedium?.copyWith(color: c.error),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: -6,
                        children: widget.item.travelUserNames
                            .map(
                              (name) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: c.primary.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: c.primary.withOpacity(.35),
                                  ),
                                ),
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    color: c.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: c.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
