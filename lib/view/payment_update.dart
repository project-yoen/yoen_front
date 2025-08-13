// lib/view/payment_update_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/model/payment_image_response.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/category_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';
import 'package:yoen_front/view/travel_settlement_update.dart';

import '../data/enums/status.dart';

class PaymentUpdateScreen extends ConsumerStatefulWidget {
  final int paymentId;
  final int travelId;
  final String paymentType;

  const PaymentUpdateScreen({
    super.key,
    required this.paymentId,
    required this.travelId,
    required this.paymentType,
  });

  @override
  ConsumerState<PaymentUpdateScreen> createState() =>
      _PaymentUpdateScreenState();
}

class _PaymentUpdateScreenState extends ConsumerState<PaymentUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoMode = AutovalidateMode.disabled;

  final _paymentNameController = TextEditingController();
  final _payerController = TextEditingController();
  final _categoryController = TextEditingController();

  final _paymentNameKey = GlobalKey<FormFieldState>();
  final _payerKey = GlobalKey<FormFieldState>();
  final _categoryKey = GlobalKey<FormFieldState>();

  final _nameFocus = FocusNode();
  final _categoryFocus = FocusNode();

  // 새로 추가할 이미지(업데이트 저장 시 파라미터로 전달)
  final List<XFile> _newImages = [];

  @override
  void initState() {
    super.initState();
    // 상세 조회 후 드래프트 생성
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(paymentNotifierProvider.notifier);
      notifier.beginEditFromSelected();

      final draft = ref.read(paymentNotifierProvider).editDraft;
      if (draft != null) {
        _syncTextControllers(draft);
      }
    });
  }

  @override
  void dispose() {
    _paymentNameController.dispose();
    _payerController.dispose();
    _categoryController.dispose();
    _nameFocus.dispose();
    _categoryFocus.dispose();
    super.dispose();
  }

  void _syncTextControllers(PaymentEditDraft draft) {
    _paymentNameController.text = draft.paymentName ?? '';
    _payerController.text = draft.payerName ?? '';
    _categoryController.text = draft.categoryName ?? '';
    setState(() {});
  }

  InputDecoration _dec({
    required String label,
    String? hint,
    Widget? suffixIcon,
    IconData? prefixIcon,
  }) {
    final c = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: c.surfaceVariant.withOpacity(.25),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.primary),
      ),
    );
  }

  Widget _clearSuffix(TextEditingController ctrl) {
    if (ctrl.text.isEmpty) return const SizedBox.shrink();
    return IconButton(
      tooltip: '지우기',
      icon: const Icon(Icons.close_rounded),
      onPressed: () {
        ctrl.clear();
        setState(() {}); // suffix 즉시 반영
      },
    );
  }

  Future<void> _pickNewImages() async {
    FocusScope.of(context).unfocus();
    final picker = ImagePicker();

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('앨범에서 선택'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
          ],
        ),
      ),
    );

    if (action == 'gallery') {
      final files = await picker.pickMultiImage();
      if (files.isNotEmpty) setState(() => _newImages.addAll(files));
    } else if (action == 'camera') {
      final file = await picker.pickImage(source: ImageSource.camera);
      if (file != null) setState(() => _newImages.add(file));
    }
  }

  void _goNext() {
    final ok = _formKey.currentState!.validate();
    if (!ok) {
      setState(() => _autoMode = AutovalidateMode.onUserInteraction);
      return;
    }

    // 이름 변경 반영
    ref
        .read(paymentNotifierProvider.notifier)
        .updateEditField(paymentName: _paymentNameController.text.trim());

    // 정산 항목 화면으로 이동(새 이미지 리스트 전달)
    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (_) => TravelSettlementUpdateScreen(
              travelId: widget.travelId,
              paymentType: widget.paymentType,
              newImages: _newImages, // 여기서 전달
            ),
          ),
        )
        .then((saved) {
          if (saved == true) Navigator.of(context).pop(true);
        });
  }

  String _formatPayTime(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('yyyy.MM.dd (E) a h:mm', 'ko_KR').format(dt);
    // 앱 전역 locale/intl 초기화는 기존과 동일
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentNotifierProvider);
    final notifier = ref.read(paymentNotifierProvider.notifier);
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // 드래프트가 아직 없으면 로딩/에러 처리
    if (state.getDetailsStatus == Status.loading || state.editDraft == null) {
      if (state.getDetailsStatus == Status.error) {
        return Scaffold(
          appBar: AppBar(title: const Text('결제 수정')),
          body: Center(
            child: Text(
              state.errorMessage ?? '상세 정보를 불러오지 못했습니다.',
              style: TextStyle(color: c.error),
            ),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('결제 수정')),
        body: const Center(child: ProgressBadge(label: "불러오는 중")),
      );
    }

    final draft = state.editDraft!;

    // 컨트롤러 싱크(첫 빌드 이후 beginEditFromSelected 호출 타이밍 보정)
    if (_paymentNameController.text.isEmpty &&
        (draft.paymentName ?? '').isNotEmpty) {
      _syncTextControllers(draft);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('결제 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoMode,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    // 결제 방식
                    _buildPaymentMethodSelector(draft, notifier),
                    const SizedBox(height: 16),

                    // 결제자 유형
                    _buildPayerTypeSelector(draft, notifier),
                    const SizedBox(height: 16),

                    if (draft.payerType == 'INDIVIDUAL') ...[
                      _buildPayerSelector(draft, notifier),
                      const SizedBox(height: 16),
                    ],

                    // 통화
                    _buildCurrencySelector(draft, notifier),
                    const SizedBox(height: 16),

                    // 결제 시간
                    _buildTimePicker(draft, notifier),
                    const SizedBox(height: 16),

                    // 결제 이름
                    TextFormField(
                      key: _paymentNameKey,
                      controller: _paymentNameController,
                      focusNode: _nameFocus,
                      decoration: _dec(
                        label: '결제 이름',
                        hint: '예) 점심 롯데리아, 저녁 이자카야',
                        prefixIcon: Icons.receipt_long_outlined,
                        suffixIcon: _clearSuffix(_paymentNameController),
                      ),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _categoryFocus.requestFocus(),
                      maxLength: 30,
                      buildCounter:
                          (
                            c, {
                            currentLength = 0,
                            isFocused = false,
                            maxLength,
                          }) => Padding(
                            padding: const EdgeInsets.only(right: 8, top: 2),
                            child: Text(
                              '$currentLength/$maxLength',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? '결제 이름을 입력하세요.'
                          : (value.trim().length < 2 ? '두 글자 이상 입력하세요.' : null),
                    ),
                    const SizedBox(height: 16),

                    // 카테고리
                    _buildCategorySelector(draft, notifier),
                    const SizedBox(height: 16),

                    // 이미지(서버 보관분 삭제/복구 + 새 이미지 추가/제거)
                    _buildImageSection(draft, notifier),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _goNext,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('다음'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(
    PaymentEditDraft draft,
    PaymentNotifier notifier,
  ) {
    final Map<String, String> paymentMethodMap = {
      '카드': 'CARD',
      '현금': 'CASH',
      '트레블카드': 'TRAVELCARD',
    };
    return DropdownButtonFormField<String>(
      value: draft.paymentMethod,
      decoration: _dec(label: '결제 방식', prefixIcon: Icons.credit_card_outlined),
      items: paymentMethodMap.entries
          .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
          .toList(),
      onChanged: (v) => notifier.updateEditField(paymentMethod: v),
    );
  }

  Widget _buildPayerTypeSelector(
    PaymentEditDraft draft,
    PaymentNotifier notifier,
  ) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'INDIVIDUAL', label: Text('개인')),
        ButtonSegment(value: 'SHAREDFUND', label: Text('공금')),
      ],
      selected: {draft.payerType ?? 'INDIVIDUAL'},
      onSelectionChanged: (sel) {
        final newType = sel.first;
        final clear = newType == 'SHAREDFUND';
        notifier.updateEditField(payerType: newType, clearPayer: clear);
        if (clear) {
          _payerController.clear();
          _payerKey.currentState?.validate();
        }
      },
    );
  }

  Widget _buildPayerSelector(PaymentEditDraft draft, PaymentNotifier notifier) {
    return TextFormField(
      key: _payerKey,
      controller: _payerController,
      readOnly: true,
      decoration: _dec(
        label: '결제자',
        hint: '결제자 선택',
        prefixIcon: Icons.person_outline,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        final selected = await showDialog<TravelUserDetailResponse>(
          context: context,
          builder: (_) => PaymentUserDialog(travelId: widget.travelId),
        );
        if (selected != null) {
          notifier.updateEditField(
            travelUserId: selected.travelUserId,
            payerName: selected.travelNickname,
          );
          _payerController.text = selected.travelNickname;
          _payerKey.currentState?.validate();
        }
      },
      validator: (value) {
        final editDraft = ref.read(paymentNotifierProvider).editDraft;
        if ((editDraft?.payerType ?? 'INDIVIDUAL') == 'INDIVIDUAL' &&
            (value == null || value.isEmpty || editDraft?.travelUserId == -1)) {
          return '결제자를 선택하세요.';
        }
        return null;
      },
    );
  }

  Widget _buildCurrencySelector(
    PaymentEditDraft draft,
    PaymentNotifier notifier,
  ) {
    return DropdownButtonFormField<String>(
      value: draft.currency,
      decoration: _dec(label: '통화', prefixIcon: Icons.attach_money),
      items: const [
        DropdownMenuItem(value: 'WON', child: Text('원')),
        DropdownMenuItem(value: 'YEN', child: Text('엔')),
      ],
      onChanged: (v) => notifier.updateEditField(currency: v),
    );
  }

  Widget _buildTimePicker(PaymentEditDraft draft, PaymentNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: _dec(label: '시간', prefixIcon: Icons.access_time),
            child: Text(
              _formatPayTime(draft.payTime),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: () async {
            final base = draft.payTime ?? DateTime.now();
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(base),
            );
            if (time != null) {
              final newTime = DateTime(
                base.year,
                base.month,
                base.day,
                time.hour,
                time.minute,
              );
              notifier.updateEditField(payTime: newTime);
            }
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('변경'),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
    PaymentEditDraft draft,
    PaymentNotifier notifier,
  ) {
    return TextFormField(
      key: _categoryKey,
      controller: _categoryController,
      focusNode: _categoryFocus,
      readOnly: true,
      decoration: _dec(
        label: '카테고리',
        hint: '카테고리 선택',
        prefixIcon: Icons.category_outlined,
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('카테고리 선택'),
            content: SizedBox(
              width: 300,
              height: 400,
              child: Consumer(
                builder: (context, ref, child) {
                  final s = ref.watch(categoryProvider(widget.paymentType));
                  return s.when(
                    data: (categories) => ListView.builder(
                      itemCount: categories.length,
                      itemBuilder: (context, i) {
                        final category = categories[i];
                        return ListTile(
                          title: Text(category.categoryName),
                          onTap: () {
                            notifier.updateEditField(
                              categoryId: category.categoryId,
                              categoryName: category.categoryName,
                            );
                            _categoryController.text = category.categoryName;
                            Navigator.of(context).pop();
                            _categoryKey.currentState?.validate();
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
          ),
        );
      },
      validator: (v) => (v == null || v.isEmpty) ? '카테고리를 선택하세요.' : null,
    );
  }

  Widget _buildImageSection(PaymentEditDraft draft, PaymentNotifier notifier) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final serverVisible = draft.visibleImages; // 삭제표시 제외
    final hasServer = serverVisible.isNotEmpty;
    final hasNew = _newImages.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '영수증 / 사진',
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),

            // 서버 이미지
            if (hasServer) ...[
              Text('기존 사진', style: t.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: serverVisible.map((img) {
                  return _ServerImageThumb(
                    image: img,
                    onRemove: () =>
                        notifier.markEditImageRemoved(img.paymentImageId!),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // 새 이미지
            Text('새로 추가', style: t.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AddPhotoCard(onTap: _pickNewImages),
                for (int i = 0; i < _newImages.length; i++)
                  _NewPhotoThumb(
                    file: File(_newImages[i].path),
                    onRemove: () => setState(() => _newImages.removeAt(i)),
                  ),
              ],
            ),

            if (!hasServer && !hasNew)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '사진이 없습니다. 필요하면 추가하세요.',
                  style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- 공통 썸네일 위젯 ---------------- */

class _AddPhotoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: c.surfaceVariant.withOpacity(.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo_outlined, color: c.primary, size: 28),
              const SizedBox(height: 6),
              Text(
                '추가',
                style: TextStyle(color: c.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPhotoThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _NewPhotoThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Image.file(file, width: 100, height: 100, fit: BoxFit.cover),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServerImageThumb extends StatelessWidget {
  final PaymentImageResponse image;
  final VoidCallback onRemove;

  const _ServerImageThumb({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final url = image.imageUrl ?? '';
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 간단히 NetworkImage로 표시. (프로젝트의 공용 위젯이 있으면 바꿔라)
          Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(3),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
