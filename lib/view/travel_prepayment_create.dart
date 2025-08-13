import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/dialog/settlement_user_dialog.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
import 'package:yoen_front/data/notifier/category_notifier.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/widget/progress_badge.dart'; // ★ 추가

import '../data/enums/status.dart';

class TravelPrepaymentCreateScreen extends ConsumerStatefulWidget {
  final int travelId;
  const TravelPrepaymentCreateScreen({super.key, required this.travelId});

  @override
  ConsumerState<TravelPrepaymentCreateScreen> createState() =>
      _TravelPrepaymentCreateScreenState();
}

class _TravelPrepaymentCreateScreenState
    extends ConsumerState<TravelPrepaymentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _payerController = TextEditingController();
  final _paymentNameController = TextEditingController();
  final _paymentAccountController = TextEditingController();
  final _settlementUsersController = TextEditingController();

  // ★ 카테고리 필드 검증을 위한 키 (선택 직후 한 번 validate)
  final _categoryKey = GlobalKey<FormFieldState>();

  String _currency = 'WON'; // 'WON' | 'YEN'
  String _paymentMethod = 'CASH'; // ▼ 선택 가능
  int? _selectedCategoryId;
  int? _selectedPayerTravelUserId;

  /// 정산 참여자(사람 기준)
  final List<int> _settleUserIds = [];
  final List<String> _settleUserNames = [];
  final Set<int> _settledUserIds = <int>{};

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  bool _isPreSettled = false;

  @override
  void dispose() {
    _categoryController.dispose();
    _payerController.dispose();
    _paymentNameController.dispose();
    _paymentAccountController.dispose();
    _settlementUsersController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (!mounted || picked.isEmpty) return;
    setState(() => _images.addAll(picked));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카테고리를 선택해주세요.')));
      return;
    }
    if (_selectedPayerTravelUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('결제자를 선택해주세요.')));
      return;
    }
    if (!_isPreSettled && _settleUserIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('정산에 포함될 사람을 선택해주세요.')));
      return;
    }

    late Settlement settlement;
    if (_isPreSettled) {
      final api = ref.read(apiServiceProvider);
      final allUsersResponse = await api.getTravelUsers(widget.travelId);
      final allUsers = allUsersResponse.data ?? [];
      settlement = Settlement(
        settlementName: _paymentNameController.text.trim(),
        amount: int.parse(_paymentAccountController.text.trim()),
        travelUsers: allUsers
            .map(
              (u) => SettlementParticipant(
                travelUserId: u.travelUserId,
                travelNickname: u.travelNickname,
                isPaid: true,
              ),
            )
            .toList(),
      );
    } else {
      final users = <SettlementParticipant>[];
      for (int i = 0; i < _settleUserIds.length; i++) {
        final id = _settleUserIds[i];
        final name = _settleUserNames[i];
        users.add(
          SettlementParticipant(
            travelUserId: id,
            travelNickname: name,
            isPaid: _settledUserIds.contains(id),
          ),
        );
      }
      settlement = Settlement(
        settlementName: _paymentNameController.text.trim(),
        amount: int.parse(_paymentAccountController.text.trim()),
        travelUsers: users,
      );
    }

    final request = PaymentRequest(
      travelId: widget.travelId,
      categoryId: _selectedCategoryId,
      payerType: 'INDIVIDUAL',
      travelUserId: _selectedPayerTravelUserId,
      payTime: DateTime.now().toIso8601String(),
      paymentName: _paymentNameController.text.trim(),
      paymentMethod: _paymentMethod,
      paymentType: 'PREPAYMENT',
      paymentAccount: int.parse(_paymentAccountController.text.trim()),
      currency: _currency,
      settlementList: [settlement],
    );

    final imageFiles = _images.map((x) => File(x.path)).toList();

    await ref
        .read(paymentNotifierProvider.notifier)
        .createPayment(request, imageFiles);

    final state = ref.read(paymentNotifierProvider);
    if (!mounted) return;

    if (state.createStatus == Status.success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? '저장에 실패했습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentNotifierProvider, (prev, next) {
      if (next.createStatus == Status.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '저장에 실패했습니다.')),
        );
      }
    });

    final paymentState = ref.watch(paymentNotifierProvider);
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final paidCount = _settledUserIds.length;

    return Scaffold(
      appBar: AppBar(title: const Text('사전사용금액 기록'), scrolledUnderElevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              children: [
                _InfoBanner(
                  icon: Icons.info_outline,
                  text: '사전사용금액은 참여자별 정산 상태를 관리할 수 있습니다.',
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    children: [
                      // 카테고리
                      _SectionCard(
                        title: '카테고리',
                        child: _selectorField(
                          fieldKey: _categoryKey, // ★ 키 전달
                          controller: _categoryController,
                          label: '카테고리',
                          hint: '카테고리 선택',
                          onTap: _showCategoryDialog, // ★ 스타일 적용된 다이얼로그
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
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 금액 + 통화(아래)
                      _SectionCard(
                        title: '금액',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _paymentAccountController,
                              decoration: InputDecoration(
                                labelText: '결제금액',
                                hintText: '숫자만 입력',
                                suffix: Text(
                                  _currency == 'WON' ? '원' : '엔',
                                  style: t.bodyMedium?.copyWith(
                                    color: c.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    signed: false,
                                    decimal: false,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return '결제금액을 입력하세요.';
                                }
                                final n = int.tryParse(v);
                                if (n == null || n <= 0) {
                                  return '유효한 금액을 입력하세요.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ChoiceChip(
                                  label: const Text('원 (WON)'),
                                  selected: _currency == 'WON',
                                  onSelected: (s) {
                                    if (s) setState(() => _currency = 'WON');
                                  },
                                ),
                                const SizedBox(width: 12),
                                ChoiceChip(
                                  label: const Text('엔 (YEN)'),
                                  selected: _currency == 'YEN',
                                  onSelected: (s) {
                                    if (s) setState(() => _currency = 'YEN');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 결제 방식
                      _SectionCard(
                        title: '결제 방식',
                        child: DropdownButtonFormField<String>(
                          value: _paymentMethod,
                          decoration: const InputDecoration(labelText: '결제 방식'),
                          items: const [
                            DropdownMenuItem(value: 'CARD', child: Text('카드')),
                            DropdownMenuItem(value: 'CASH', child: Text('현금')),
                            DropdownMenuItem(
                              value: 'TRAVELCARD',
                              child: Text('트레블카드'),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _paymentMethod = v ?? 'CASH';
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 정산
                      _SectionCard(
                        title: '정산',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('사전 정산 완료'),
                              subtitle: const Text('이 금액이 이미 정산 완료되었음을 의미합니다.'),
                              value: _isPreSettled,
                              onChanged: (v) =>
                                  setState(() => _isPreSettled = v ?? false),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),

                            if (!_isPreSettled) ...[
                              Row(
                                children: [
                                  const Icon(Icons.verified_outlined, size: 20),
                                  const SizedBox(width: 6),
                                  Text(
                                    '정산 현황  $paidCount/${_settleUserIds.length}',
                                    style: t.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_settleUserIds.isNotEmpty &&
                                      paidCount == _settleUserIds.length)
                                    Icon(Icons.check_circle, color: c.primary),
                                ],
                              ),
                              const SizedBox(height: 8),

                              if (_settleUserIds.isEmpty)
                                Text(
                                  '참여 유저를 먼저 선택하세요.',
                                  style: t.bodyMedium?.copyWith(color: c.error),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: -6,
                                  children: List.generate(
                                    _settleUserIds.length,
                                    (i) {
                                      final uid = _settleUserIds[i];
                                      final name = _settleUserNames[i];
                                      final selected = _settledUserIds.contains(
                                        uid,
                                      );
                                      return FilterChip(
                                        label: Text(name),
                                        selected: selected,
                                        onSelected: (val) {
                                          setState(() {
                                            if (val) {
                                              _settledUserIds.add(uid);
                                            } else {
                                              _settledUserIds.remove(uid);
                                            }
                                          });
                                        },
                                        avatar: selected
                                            ? const Icon(Icons.done)
                                            : null,
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: OutlinedButton.icon(
                                  onPressed: _pickSettlementUsers,
                                  icon: const Icon(Icons.group_add_outlined),
                                  label: const Text('참여 유저 선택/변경'),
                                ),
                              ),
                              const SizedBox(height: 6),

                              if (_settleUserIds.isNotEmpty)
                                Text(
                                  '사전정산 완료: $paidCount / ${_settleUserIds.length}',
                                  style: t.bodySmall?.copyWith(
                                    color: c.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 이미지
                      _SectionCard(title: '영수증 이미지', child: _imagePickerRow()),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),

                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: paymentState.createStatus == Status.loading
                        ? null
                        : _submit,
                    icon: paymentState.createStatus == Status.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('저장'),
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

  // ---------------- 정산 유저 선택/반영 ----------------

  Future<void> _pickSettlementUsers() async {
    final initial = List<SettlementParticipant>.generate(
      _settleUserIds.length,
      (i) {
        final id = _settleUserIds[i];
        final name = _settleUserNames[i];
        return SettlementParticipant(
          travelUserId: id,
          travelNickname: name,
          isPaid: _settledUserIds.contains(id),
        );
      },
    );

    final selected = await showDialog<List<SettlementParticipant>>(
      context: context,
      builder: (_) => SettlementUserDialog(
        travelId: widget.travelId,
        initialParticipants: initial,
        showPaidCheckBox: false, // chip에서 토글하므로 체크박스 숨김
      ),
    );

    if (selected == null) return;

    _settleUserIds
      ..clear()
      ..addAll(selected.map((e) => e.travelUserId));
    _settleUserNames
      ..clear()
      ..addAll(selected.map((e) => e.travelNickname ?? ''));
    _settledUserIds
      ..clear()
      ..addAll(
        selected.where((e) => (e.isPaid ?? false)).map((e) => e.travelUserId),
      );

    _settlementUsersController.text = _settleUserNames
        .where((s) => s.isNotEmpty)
        .join(', ');
    setState(() {});
  }

  // ---------------- 카테고리 다이얼로그 (요청 스타일 적용) ----------------

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('카테고리 선택'),
          content: SizedBox(
            width: 300,
            height: 400,
            child: Consumer(
              builder: (context, ref, child) {
                final state = ref.watch(
                  categoryProvider("PREPAYMENT"),
                ); // ★ 타입 고정
                return state.when(
                  data: (categories) {
                    return SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return ListTile(
                            title: Text(category.categoryName),
                            onTap: () {
                              // 상태 반영
                              _selectedCategoryId = category.categoryId;
                              _categoryController.text = category.categoryName;

                              Navigator.of(context).pop();

                              // ★ 선택 직후 한 번만 검증 트리거
                              _categoryKey.currentState?.validate();
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: ProgressBadge(label: "리스트 로딩 중")),
                  error: (error, stack) => Center(child: Text('오류: $error')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------- UI Helpers ----------------

  Widget _selectorField({
    Key? fieldKey, // ★ 선택적으로 FormFieldKey 전달
    required TextEditingController controller,
    required String label,
    required String hint,
    required VoidCallback onTap,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: fieldKey, // ★ 여기서 키 적용
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

  Widget _imagePickerRow() {
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
          ..._images.asMap().entries.map((e) {
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
                        onTap: () => _removeImage(idx),
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

  // ---------------- Dialogs ----------------

  void _showPayerDialog() async {
    final selectedUser = await showDialog<TravelUserDetailResponse>(
      context: context,
      builder: (_) => PaymentUserDialog(travelId: widget.travelId),
    );
    if (selectedUser != null) {
      setState(() {
        _payerController.text = selectedUser.travelNickname;
        _selectedPayerTravelUserId = selectedUser.travelUserId;
      });
    }
  }
}

// ---------------- 재사용 위젯 ----------------

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
