import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/model/category_response.dart';
import 'package:yoen_front/data/notifier/category_notifier.dart';
import 'package:flutter/material.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/payment_create_notifier.dart';
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
  final _paymentNameController = TextEditingController();
  final _payerController = TextEditingController();
  final _categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _paymentNameController.clear();
    _payerController.clear();
    _categoryController.clear();
    final initialDate = ref.read(dateNotifierProvider) ?? DateTime.now();
    // Use WidgetsBinding to avoid calling notifier during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(paymentCreateNotifierProvider.notifier).initialize(initialDate);
    });
  }

  @override
  void dispose() {
    _paymentNameController.dispose();
    _payerController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(paymentCreateNotifierProvider.notifier)
          .updateField(paymentName: _paymentNameController.text);

      Navigator.of(context)
          .push<bool>(
            MaterialPageRoute(
              builder: (context) => TravelSettlementCreateScreen(
                travelId: widget.travelId,
                paymentType: widget.paymentType,
              ),
            ),
          )
          .then((result) {
            if (result == true) {
              Navigator.of(context).pop(true);
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentCreateNotifierProvider);
    final notifier = ref.read(paymentCreateNotifierProvider.notifier);

    // Set initial text for controllers if they are empty
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
                    TextFormField(
                      controller: _paymentNameController,
                      decoration: const InputDecoration(labelText: '결제 이름'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '결제 이름을 입력하세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    _buildCategorySelector(notifier),
                    const SizedBox(height: 16.0),
                    _buildImagePicker(state, notifier),
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
        }
      },
    );
  }

  Widget _buildPayerSelector(PaymentCreateNotifier notifier) {
    return TextFormField(
      controller: _payerController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: '결제자',
        suffixIcon: Icon(Icons.arrow_drop_down),
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
        payerName: selectedUser.travelNickName,
      );
      _payerController.text = selectedUser.travelNickName;
    }
  }

  Widget _buildTimePicker(
    PaymentCreateState state,
    PaymentCreateNotifier notifier,
  ) {
    return Row(
      children: [
        const Text('시간:'),
        const SizedBox(width: 16.0),
        TextButton(
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
          child: Text(
            '${state.payTime!.hour}:${state.payTime!.minute.toString().padLeft(2, '0')}',
          ),
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
      decoration: const InputDecoration(labelText: '결제 방식'),
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

  Widget _buildCategorySelector(PaymentCreateNotifier notifier) {
    return TextFormField(
      controller: _categoryController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: '카테고리',
        suffixIcon: Icon(Icons.arrow_drop_down),
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
                            },
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('오류: $error')),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildImagePicker(
    PaymentCreateState state,
    PaymentCreateNotifier notifier,
  ) {
    final picker = ImagePicker();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('사진'),
        const SizedBox(height: 8.0),
        GestureDetector(
          onTap: () async {
            FocusScope.of(context).unfocus();
            final List<XFile> pickedFiles = await picker.pickMultiImage();
            notifier.addImages(pickedFiles);
          },
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4.0,
            mainAxisSpacing: 4.0,
          ),
          itemCount: state.images.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Image.file(
                  File(state.images[index].path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => notifier.removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
