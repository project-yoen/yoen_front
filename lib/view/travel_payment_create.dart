import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/notifier/category_notifier.dart';
import 'package:flutter/material.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/payment_create_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart'; // nation 읽기
import 'package:yoen_front/data/widget/progress_badge.dart';
import 'package:yoen_front/view/travel_settlement_create.dart';
import 'dart:io';

class TravelPaymentCreateScreen extends ConsumerStatefulWidget {
  final String paymentType;
  final int travelId;
  const TravelPaymentCreateScreen({
    super.key,
    required this.paymentType,
    required this.travelId,
  });

  @override
  ConsumerState<TravelPaymentCreateScreen> createState() =>
      _TravelPaymentCreateScreenState();
}

class _TravelPaymentCreateScreenState
    extends ConsumerState<TravelPaymentCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // 제출 실패 전까지는 조용, 이후 실시간 검증
  AutovalidateMode _autoMode = AutovalidateMode.disabled;

  // 텍스트 컨트롤러
  final _paymentNameController = TextEditingController();
  final _payerController = TextEditingController();
  final _categoryController = TextEditingController();

  // 개별 폼필드 키(선택 필드 선택 직후 1회 검증용)
  final _paymentNameKey = GlobalKey<FormFieldState>();
  final _payerKey = GlobalKey<FormFieldState>();
  final _categoryKey = GlobalKey<FormFieldState>();

  // 포커스 이동
  final _nameFocus = FocusNode();
  final _categoryFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _paymentNameController.clear();
    _payerController.clear();
    _categoryController.clear();

    final initialDate = ref.read(dateNotifierProvider) ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(paymentCreateNotifierProvider.notifier);

      // nation 기반 초기 통화 세팅 (JAPAN -> YEN, 그 외 -> WON)
      final nation =
          ref.read(travelListNotifierProvider).selectedTravel?.nation ??
          'KOREA';
      final defaultCurrency = (nation == 'JAPAN') ? 'YEN' : 'WON';
      notifier.updateField(currency: defaultCurrency);

      notifier.initialize(initialDate);
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

  // 공통 데코레이션
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

  // 클리어 버튼
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

  void _goToNextStep() {
    final ok = _formKey.currentState!.validate();
    if (!ok) {
      setState(() => _autoMode = AutovalidateMode.onUserInteraction);
      return;
    }

    final nation =
        ref.read(travelListNotifierProvider).selectedTravel?.nation ?? 'KOREA';
    final currencyCode =
        (ref.read(paymentCreateNotifierProvider).currency) ??
        (nation == 'JAPAN' ? 'YEN' : 'WON');

    ref
        .read(paymentCreateNotifierProvider.notifier)
        .updateField(paymentName: _paymentNameController.text);

    Navigator.of(context)
        .push<bool>(
          MaterialPageRoute(
            builder: (context) => TravelSettlementCreateScreen(
              travelId: widget.travelId,
              paymentType: widget.paymentType,
              currencyCode: currencyCode, // 여기!
            ),
          ),
        )
        .then((result) {
          if (result == true) {
            Navigator.of(context).pop(true);
          }
        });
  }

  Future<void> _pickImages(PaymentCreateNotifier notifier) async {
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
      if (files.isNotEmpty) notifier.addImages(files);
    } else if (action == 'camera') {
      final file = await picker.pickImage(source: ImageSource.camera);
      if (file != null) notifier.addImages([file]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentCreateNotifierProvider);
    final notifier = ref.read(paymentCreateNotifierProvider.notifier);
    final c = Theme.of(context).colorScheme;

    // 초기 텍스트 주입
    if (_payerController.text.isEmpty && state.payerName != null) {
      _payerController.text = state.payerName!;
    }
    if (_categoryController.text.isEmpty && state.categoryName != null) {
      _categoryController.text = state.categoryName!;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('결제 내역 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoMode, // 제출 실패 후에만 실시간 검증
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildPayerTypeSelector(state, notifier),
                    const SizedBox(height: 16.0),

                    if (state.payTime != null)
                      _buildTimePicker(state, notifier),
                    const SizedBox(height: 16.0),

                    if (state.payerType == 'INDIVIDUAL') ...[
                      _buildPayerSelector(notifier),
                      const SizedBox(height: 16.0),
                    ],

                    _buildPaymentMethodSelector(state, notifier),
                    const SizedBox(height: 16.0),

                    // 통화 선택 (엔/원 라벨, 내부 값은 YEN/WON)
                    _buildCurrencySelector(state, notifier),
                    const SizedBox(height: 16.0),

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
                      onChanged: (_) => setState(() {}),
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
                    const SizedBox(height: 16.0),

                    // 카테고리
                    _buildCategorySelector(notifier),
                    const SizedBox(height: 16.0),

                    // 사진 영역
                    Card(
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: state.images.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _AddPhotoCard(
                                    onTap: () => _pickImages(notifier),
                                  );
                                }
                                final img = state.images[index - 1];
                                return _PhotoThumb(
                                  file: File(img.path),
                                  onRemove: () =>
                                      notifier.removeImage(index - 1),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _goToNextStep,
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

  Widget _buildPayerTypeSelector(
    PaymentCreateState state,
    PaymentCreateNotifier notifier,
  ) {
    return SegmentedButton<String>(
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(value: 'INDIVIDUAL', label: Text('개인')),
        ButtonSegment<String>(value: 'SHAREDFUND', label: Text('공금')),
      ],
      selected: {state.payerType!},
      onSelectionChanged: (Set<String> newSelection) {
        final newPayerType = newSelection.first;
        final bool shouldClearPayer = newPayerType == 'SHAREDFUND';
        notifier.updateField(
          payerType: newPayerType,
          clearPayer: shouldClearPayer,
        );
        if (shouldClearPayer) {
          _payerController.clear();
          // 선택 변경 직후 1회만 검증
          _payerKey.currentState?.validate();
        }
      },
    );
  }

  Widget _buildPayerSelector(PaymentCreateNotifier notifier) {
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
      onTap: () => _showPayerDialog(notifier),
      validator: (value) {
        if (ref.read(paymentCreateNotifierProvider).payerType == 'INDIVIDUAL' &&
            (value == null || value.isEmpty)) {
          return '결제자를 선택하세요.';
        }
        return null;
      },
    );
  }

  void _showPayerDialog(PaymentCreateNotifier notifier) async {
    final selectedUser = await showDialog<TravelUserDetailResponse>(
      context: context,
      builder: (context) => PaymentUserDialog(travelId: widget.travelId),
    );

    if (selectedUser != null) {
      notifier.updateField(
        payerTravelUserId: selectedUser.travelUserId,
        payerName: selectedUser.travelNickname,
      );
      _payerController.text = selectedUser.travelNickname;
      // 선택 직후 해당 필드만 재검증
      _payerKey.currentState?.validate();
    }
  }

  Widget _buildTimePicker(
    PaymentCreateState state,
    PaymentCreateNotifier notifier,
  ) {
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: _dec(label: '시간', prefixIcon: Icons.access_time),
            child: Text(
              '${state.payTime!.hour.toString().padLeft(2, '0')}:${state.payTime!.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonalIcon(
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(state.payTime!),
            );
            if (time != null) {
              final newTime = DateTime(
                state.payTime!.year,
                state.payTime!.month,
                state.payTime!.day,
                time.hour,
                time.minute,
              );
              notifier.updateField(payTime: newTime);
            }
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('변경'),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector(
    PaymentCreateState state,
    PaymentCreateNotifier notifier,
  ) {
    final Map<String, String> paymentMethodMap = {
      '카드': 'CARD',
      '현금': 'CASH',
      '트레블카드': 'TRAVELCARD',
    };
    return DropdownButtonFormField<String>(
      value: state.paymentMethod,
      decoration: _dec(label: '결제 방식', prefixIcon: Icons.credit_card_outlined),
      items: paymentMethodMap.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.value, child: Text(entry.key)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          notifier.updateField(paymentMethod: value);
        }
      },
    );
  }

  // 통화 드롭다운 (엔/원 보기, 내부값 YEN/WON)
  Widget _buildCurrencySelector(
    PaymentCreateState state,
    PaymentCreateNotifier notifier,
  ) {
    const labelFor = {'WON': '원', 'YEN': '엔'};

    return DropdownButtonFormField<String>(
      value: state.currency, // YEN/WON
      decoration: _dec(label: '통화', prefixIcon: Icons.attach_money),
      items: const [
        DropdownMenuItem(value: 'WON', child: Text('원')),
        DropdownMenuItem(value: 'YEN', child: Text('엔')),
      ],
      onChanged: (value) {
        if (value != null) {
          notifier.updateField(currency: value);
        }
      },
      // null일 때 nation 기반 힌트
      hint: Text(
        labelFor[(ref.read(travelListNotifierProvider).selectedTravel?.nation ==
                    'JAPAN')
                ? 'YEN'
                : 'WON'] ??
            '원',
      ),
    );
  }

  Widget _buildCategorySelector(PaymentCreateNotifier notifier) {
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
      onTap: () => _showCategoryDialog(notifier),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '카테고리를 선택하세요.';
        }
        return null;
      },
    );
  }

  void _showCategoryDialog(PaymentCreateNotifier notifier) {
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
                final state = ref.watch(categoryProvider(widget.paymentType));
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
                              notifier.updateField(
                                categoryId: category.categoryId,
                                categoryName: category.categoryName,
                              );
                              _categoryController.text = category.categoryName;
                              Navigator.of(context).pop();

                              // 선택 직후 한 번만 검증
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
}

/* ===== 공통 썸네일/추가 카드 ===== */
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
        decoration: BoxDecoration(
          color: c.surfaceVariant.withOpacity(.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo_outlined, color: c.primary, size: 32),
              const SizedBox(height: 6),
              Text(
                '사진 추가',
                style: TextStyle(
                  color: c.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _PhotoThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.cover),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
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
