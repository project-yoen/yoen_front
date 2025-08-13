// lib/ui/travel_prepayment_update_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/dialog/settlement_user_dialog.dart';
import 'package:yoen_front/data/model/payment_create_request.dart'; // Settlement, SettlementParticipant
import 'package:yoen_front/data/model/payment_update_request.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/notifier/category_notifier.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';

import '../data/enums/status.dart';
import '../data/model/settlement_item.dart';

class TravelPrepaymentUpdateScreen extends ConsumerStatefulWidget {
  final bool isDialog;
  const TravelPrepaymentUpdateScreen({super.key, this.isDialog = false});

  @override
  ConsumerState<TravelPrepaymentUpdateScreen> createState() =>
      _TravelPrepaymentUpdateScreenState();
}

class _TravelPrepaymentUpdateScreenState
    extends ConsumerState<TravelPrepaymentUpdateScreen> {
  final _formKey = GlobalKey<FormState>();

  // 카테고리 선택 직후 1회 검증 키
  final _categoryFieldKey = GlobalKey<FormFieldState>();

  // 표시용 컨트롤러 (draft → text 최초 1회 주입)
  final _categoryController = TextEditingController();
  final _payerController = TextEditingController();
  final _paymentNameController = TextEditingController();

  bool _hydrated = false;

  // 신규 추가 이미지
  final _picker = ImagePicker();
  final List<XFile> _newImages = [];

  @override
  void initState() {
    super.initState();
    // selectedPayment는 이미 로드되어 있다고 가정. editDraft 없으면 한 번 생성
    final draft = ref.read(paymentNotifierProvider).editDraft;
    if (draft == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(paymentNotifierProvider.notifier).beginEditFromSelected();
        setState(() {}); // 빌드 트리거
      });
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _payerController.dispose();
    _paymentNameController.dispose();
    super.dispose();
  }

  // ---------- 액션 ----------

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (!mounted || picked.isEmpty) return;
    setState(() => _newImages.addAll(picked));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  String _formatCurrency(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );

  Future<void> _submit() async {
    final notifier = ref.read(paymentNotifierProvider.notifier);
    final state = ref.read(paymentNotifierProvider);
    final draft = state.editDraft;
    final detail = state.selectedPayment;

    if (draft == null || detail == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('편집 데이터를 불러오지 못했습니다.')));
      return;
    }

    // 폼 전체 검증
    if (!_formKey.currentState!.validate()) return;

    // 단일 정산 항목 보장
    final item = (draft.settlementItems.isNotEmpty)
        ? draft.settlementItems.first
        : SettlementItem(
            nameController: TextEditingController(), // 사용하지 않지만 타입 유지
            amountController: TextEditingController(),
            travelUserIds: const [],
            travelUserNames: const [],
            settledUserIds: <int>{},
          );

    // 정산 항목(1개) → Settlement 변환 (settlementName은 결제 이름과 동일하게 전송)
    final settlementName = _paymentNameController.text.trim();
    final amount = int.tryParse(item.amountController.text.trim()) ?? 0;

    final users = <SettlementParticipant>[];
    for (int i = 0; i < item.travelUserIds.length; i++) {
      final uid = item.travelUserIds[i];
      final uname = (i < item.travelUserNames.length)
          ? item.travelUserNames[i]
          : '';
      users.add(
        SettlementParticipant(
          travelUserId: uid,
          travelNickname: uname,
          isPaid: item.settledUserIds.contains(uid),
        ),
      );
    }

    final settlements = <Settlement>[
      Settlement(
        settlementName: settlementName,
        amount: amount,
        travelUsers: users,
      ),
    ];

    // 요청 본문
    final req = PaymentUpdateRequest(
      paymentId: draft.paymentId,
      travelId: detail.travelId ?? 0,
      paymentType: detail.paymentType ?? 'PREPAYMENT',
      paymentName: _paymentNameController.text.trim(),
      paymentMethod: draft.paymentMethod, // CARD/CASH/TRAVELCARD
      payerType: draft.payerType, // INDIVIDUAL/SHAREDFUND
      categoryId: draft.categoryId,
      travelUserId: draft.travelUserId,
      payTime: detail.payTime, // 필요 시 변경 가능
      paymentAccount: amount, // ★ 단일 항목 금액 = 합계
      currency: draft.currency,
      settlementList: settlements,
      removeImageIds: draft.removedImageIds.toList(), // ★ 서버 이미지 삭제
    );

    // 신규 이미지 파일
    final files = _newImages.map((x) => File(x.path)).toList();

    await notifier.updatePayment(req, files, widget.isDialog);
  }

  // ---------- Dialogs ----------

  void _showPayerDialog() async {
    final state = ref.read(paymentNotifierProvider);
    final travelId = state.selectedPayment?.travelId ?? 0;

    final selected = await showDialog<TravelUserDetailResponse>(
      context: context,
      builder: (_) => PaymentUserDialog(travelId: travelId),
    );
    if (selected == null) return;

    _payerController.text = selected.travelNickname;
    ref
        .read(paymentNotifierProvider.notifier)
        .updateEditField(
          travelUserId: selected.travelUserId,
          payerName: selected.travelNickname,
        );
    setState(() {});
  }

  void _showCategoryDialog() {
    final notifier = ref.read(paymentNotifierProvider.notifier);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('카테고리 선택'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Consumer(
              builder: (context, ref, _) {
                final state = ref.watch(categoryProvider("PREPAYMENT"));
                return state.when(
                  data: (categories) => ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final c = categories[index];
                      return ListTile(
                        title: Text(c.categoryName),
                        onTap: () {
                          notifier.updateEditField(
                            categoryId: c.categoryId,
                            categoryName: c.categoryName,
                          );
                          _categoryController.text = c.categoryName;
                          Navigator.of(context).pop();
                          _categoryFieldKey.currentState?.validate();
                        },
                      );
                    },
                  ),
                  loading: () =>
                      const Center(child: ProgressBadge(label: "리스트 로딩 중")),
                  error: (e, _) => Center(child: Text('오류: $e')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---------- 빌드 ----------

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentNotifierProvider, (prev, next) {
      // 성공 순간에 바로 pop
      if (prev?.updateStatus == Status.loading &&
          next.updateStatus == Status.success) {
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      // 에러 표시 (기존 로직 유지)
      if (next.updateStatus == Status.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '저장에 실패했습니다.')),
        );
      }
    });

    final state = ref.watch(paymentNotifierProvider);
    final draft = state.editDraft;
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // draft 준비 전 로딩
    if (draft == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('사전사용금액 수정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 단일 항목 보장 (없으면 즉시 1개 채워넣음)
    final item = draft.settlementItems.isNotEmpty
        ? draft.settlementItems.first
        : SettlementItem(
            nameController: TextEditingController(),
            amountController: TextEditingController(),
            travelUserIds: const [],
            travelUserNames: const [],
            settledUserIds: <int>{},
          );

    // 최초 1회 컨트롤러 주입
    if (!_hydrated) {
      _categoryController.text = draft.categoryName ?? '';
      _payerController.text = draft.payerName ?? '';
      _paymentNameController.text = draft.paymentName ?? '';
      _hydrated = true;
    }

    // 합계 = 단일 항목 금액
    final total = int.tryParse(item.amountController.text.trim()) ?? 0;
    final currencyLabel = (draft.currency == 'YEN') ? '엔' : '원';

    return Scaffold(
      appBar: AppBar(title: const Text('사전사용금액 수정'), scrolledUnderElevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const _InfoBanner(
                  icon: Icons.info_outline,
                  text: '정산 항목은 하나만 편집합니다. 항목 이름 입력 없이 결제 이름이 정산 이름으로 저장됩니다.',
                ),
                const SizedBox(height: 12),

                // 상단 합계 카드
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: c.outlineVariant),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.primary.withOpacity(.1),
                      child: Icon(Icons.summarize, color: c.primary),
                    ),
                    title: Text(
                      '총 정산 금액',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '정산 항목 금액입니다.',
                      style: TextStyle(color: c.onSurfaceVariant),
                    ),
                    trailing: Text(
                      '${_formatCurrency(total)} $currencyLabel',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    children: [
                      // 결제 이름
                      _SectionCard(
                        title: '결제 이름',
                        child: TextFormField(
                          controller: _paymentNameController,
                          decoration: const InputDecoration(
                            labelText: '결제이름',
                            hintText: '예) 편의점, 식사, 교통 등',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? '결제이름을 입력하세요.'
                              : null,
                          onChanged: (v) => ref
                              .read(paymentNotifierProvider.notifier)
                              .updateEditField(paymentName: v),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 카테고리
                      _SectionCard(
                        title: '카테고리',
                        child: _selectorField(
                          fieldKey: _categoryFieldKey,
                          controller: _categoryController,
                          label: '카테고리',
                          hint: '카테고리 선택',
                          onTap: _showCategoryDialog,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? '카테고리를 선택하세요.' : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 결제자
                      _SectionCard(
                        title: '결제자',
                        child: _selectorField(
                          controller: _payerController,
                          label: '결제자',
                          hint: '결제자 선택',
                          onTap: _showPayerDialog,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? '결제자를 선택하세요.' : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 결제 방식
                      _SectionCard(
                        title: '결제 방식',
                        child: DropdownButtonFormField<String>(
                          value: draft.paymentMethod ?? 'CASH',
                          decoration: const InputDecoration(labelText: '결제 방식'),
                          items: const [
                            DropdownMenuItem(value: 'CARD', child: Text('카드')),
                            DropdownMenuItem(value: 'CASH', child: Text('현금')),
                            DropdownMenuItem(
                              value: 'TRAVELCARD',
                              child: Text('트레블카드'),
                            ),
                          ],
                          onChanged: (v) => ref
                              .read(paymentNotifierProvider.notifier)
                              .updateEditField(paymentMethod: v ?? 'CASH'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 통화
                      _SectionCard(
                        title: '통화',
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('원 (WON)'),
                              selected: (draft.currency ?? 'WON') == 'WON',
                              onSelected: (s) {
                                if (s) {
                                  ref
                                      .read(paymentNotifierProvider.notifier)
                                      .updateEditField(currency: 'WON');
                                  setState(() {});
                                }
                              },
                            ),
                            const SizedBox(width: 12),
                            ChoiceChip(
                              label: const Text('엔 (YEN)'),
                              selected: (draft.currency ?? 'WON') == 'YEN',
                              onSelected: (s) {
                                if (s) {
                                  ref
                                      .read(paymentNotifierProvider.notifier)
                                      .updateEditField(currency: 'YEN');
                                  setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 정산 항목 (단일, 이름 필드 제거)
                      _SectionCard(
                        title: '정산 항목',
                        child: _SingleSettlementCard(
                          item: item,
                          currencyLabel: currencyLabel,
                          onPickUsers: () async {
                            final current =
                                List<SettlementParticipant>.generate(
                                  item.travelUserIds.length,
                                  (i) => SettlementParticipant(
                                    travelUserId: item.travelUserIds[i],
                                    travelNickname:
                                        (i < item.travelUserNames.length)
                                        ? item.travelUserNames[i]
                                        : '',
                                    isPaid: item.settledUserIds.contains(
                                      item.travelUserIds[i],
                                    ),
                                  ),
                                );
                            final selected =
                                await showDialog<List<SettlementParticipant>>(
                                  context: context,
                                  builder: (_) => SettlementUserDialog(
                                    travelId:
                                        ref
                                            .read(paymentNotifierProvider)
                                            .selectedPayment
                                            ?.travelId ??
                                        0,
                                    initialParticipants: current,
                                    showPaidCheckBox: false,
                                  ),
                                );
                            if (selected != null) {
                              final ids = selected
                                  .map((e) => e.travelUserId)
                                  .toList();
                              final names = selected
                                  .map((e) => e.travelNickname ?? '')
                                  .toList();
                              ref
                                  .read(paymentNotifierProvider.notifier)
                                  .setEditParticipants(
                                    index: 0,
                                    userIds: ids,
                                    userNames: names,
                                  );
                              setState(() {});
                            }
                          },
                          onToggleUser: (userId, val) => ref
                              .read(paymentNotifierProvider.notifier)
                              .toggleEditUserSettled(
                                index: 0,
                                userId: userId,
                                value: val,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 기존 이미지(삭제 토글) + 신규 추가
                      if (state.editDraft?.visibleImages.isNotEmpty ==
                          true) ...[
                        _SectionCard(
                          title: '기존 영수증 이미지',
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: state.editDraft!.visibleImages.map((
                                img,
                              ) {
                                final id = img.paymentImageId!;
                                final url = img.imageUrl ?? '';
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    alignment: Alignment.topRight,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          url,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Material(
                                          color: Colors.black54,
                                          shape: const CircleBorder(),
                                          child: InkWell(
                                            customBorder: const CircleBorder(),
                                            onTap: () {
                                              ref
                                                  .read(
                                                    paymentNotifierProvider
                                                        .notifier,
                                                  )
                                                  .markEditImageRemoved(id);
                                              setState(() {});
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(4.0),
                                              child: Icon(
                                                Icons.delete_outline,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if ((state.editDraft?.removedImageIds.isNotEmpty ??
                          false))
                        _SectionCard(
                          title: '삭제 예정 이미지',
                          child: Wrap(
                            spacing: 8,
                            children: state.editDraft!.removedImageIds.map((
                              id,
                            ) {
                              return ActionChip(
                                label: Text('#$id 취소'),
                                onPressed: () {
                                  ref
                                      .read(paymentNotifierProvider.notifier)
                                      .undoEditImageRemoved(id);
                                  setState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ),

                      if ((state.editDraft?.removedImageIds.isNotEmpty ??
                          false))
                        const SizedBox(height: 12),

                      _SectionCard(title: '영수증 이미지(추가)', child: _newImageRow()),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: state.updateStatus == Status.loading
                        ? null
                        : _submit,
                    label: state.updateStatus == Status.loading
                        ? Center(child: ProgressBadge(label: "저장 중"))
                        : const Text("저장"),
                    style: FilledButton.styleFrom(
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  // ---------- 공통 위젯 ----------

  Widget _selectorField({
    Key? fieldKey,
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      readOnly: true,
      onTap: onTap,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }

  Widget _newImageRow() {
    final c = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: c.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.outlineVariant),
              ),
              child: const Center(child: Icon(Icons.add_a_photo)),
            ),
          ),
          const SizedBox(width: 8),
          ..._newImages.asMap().entries.map((e) {
            final idx = e.key;
            final img = e.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(img.path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black54,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _removeNewImage(idx),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------- 단일 정산 항목 카드 (이름 필드 제거) ----------
class _SingleSettlementCard extends StatefulWidget {
  final SettlementItem item;
  final String currencyLabel; // '원' | '엔'
  final VoidCallback onPickUsers;
  final void Function(int userId, bool selected) onToggleUser;

  const _SingleSettlementCard({
    required this.item,
    required this.currencyLabel,
    required this.onPickUsers,
    required this.onToggleUser,
  });

  @override
  State<_SingleSettlementCard> createState() => _SingleSettlementCardState();
}

class _SingleSettlementCardState extends State<_SingleSettlementCard> {
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final total = widget.item.travelUserIds.length;
    final done = widget.item.settledUserIds.length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            // 금액 (통화 라벨만 표시)
            TextFormField(
              controller: widget.item.amountController,
              decoration: InputDecoration(
                labelText: '금액',
                hintText: '숫자만 입력',
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    widget.currencyLabel,
                    style: t.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return '금액을 입력하세요.';
                final parsed = int.tryParse(v);
                if (parsed == null || parsed <= 0) return '올바른 금액을 입력하세요.';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // 정산 현황
            Row(
              children: [
                const Icon(Icons.verified_outlined, size: 20),
                const SizedBox(width: 6),
                Text(
                  '정산 현황  $done/$total',
                  style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (total > 0 && done == total)
                  Icon(Icons.check_circle, color: c.primary),
              ],
            ),
            const SizedBox(height: 8),

            // 참여자 Chip + 완료 토글
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
                      onSelected: (val) => widget.onToggleUser(uid, val),
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

// ---------- 재사용 위젯 ----------
class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.primary.withOpacity(.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: c.onSurface, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
