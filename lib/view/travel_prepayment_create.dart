import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoen_front/data/dialog/settlement_user_dialog.dart';
import 'package:yoen_front/data/model/category_response.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
import 'package:yoen_front/data/notifier/category_notifier.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';

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
  String _currency = 'WON';
  int? _selectedCategoryId;
  int? _selectedPayerTravelUserId;
  List<SettlementParticipantDto> _settlementParticipants = [];
  List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

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
    final pickedFiles = await _picker.pickMultiImage();
    setState(() {
      _images.addAll(pickedFiles);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('카테고리를 선택해주세요.')));
        return;
      }
      if (_selectedPayerTravelUserId == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('결제자를 선택해주세요.')));
        return;
      }
      if (_settlementParticipants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('정산에 포함될 사람을 선택해주세요.')));
        return;
      }

      final settlement = Settlement(
        settlementName: _paymentNameController.text,
        amount: int.parse(_paymentAccountController.text),
        isPaid: false, // 사전사용금액의 정산 자체는 완료되지 않음
        travelUsers: _settlementParticipants
            .map((p) => SettlementParticipantRequestDto(
                travelUserId: p.travelUserId,
                isPaid: p.isPaid)) // 다이얼로그에서 선택한 isPaid 값을 사용
            .toList(),
      );

      final request = PaymentCreateRequest(
        travelId: widget.travelId,
        categoryId: _selectedCategoryId,
        payerType: 'USER',
        travelUserId: _selectedPayerTravelUserId,
        payTime: DateTime.now().toIso8601String(),
        paymentName: _paymentNameController.text,
        paymentMethod: 'CASH', // 사전사용금액은 현금으로 고정
        paymentType: 'PREPAYMENT',
        paymentAccount: int.parse(_paymentAccountController.text),
        currency: _currency,
        settlementList: [settlement],
      );

      final imageFiles = _images.map((x) => File(x.path)).toList();

      ref
          .read(paymentNotifierProvider.notifier)
          .createPayment(request, imageFiles)
          .then((_) {
        if (ref.read(paymentNotifierProvider).createStatus == Status.success) {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    ref.read(paymentNotifierProvider).errorMessage ?? '저장에 실패했습니다.')),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('사전사용금액 기록')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCategorySelector(),
                const SizedBox(height: 16.0),
                _buildPayerSelector(),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _paymentNameController,
                  decoration: const InputDecoration(
                    labelText: '결제이름',
                  ),
                  validator: (value) =>
                      value!.isEmpty ? '결제이름을 입력하세요.' : null,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _paymentAccountController,
                  decoration: const InputDecoration(
                    labelText: '결제금액',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value!.isEmpty ? '결제금액을 입력하세요.' : null,
                ),
                const SizedBox(height: 16.0),
                _buildCurrencySelector(),
                const SizedBox(height: 16.0),
                _buildSettlementUserSelector(),
                const SizedBox(height: 16.0),
                _buildImagePicker(),
                const SizedBox(height: 32.0),
                ElevatedButton(
                  onPressed: paymentState.createStatus == Status.loading
                      ? null
                      : _submit,
                  child: paymentState.createStatus == Status.loading
                      ? const CircularProgressIndicator()
                      : const Text('저장하기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('영수증 이미지', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.add_a_photo),
                ),
              ),
              const SizedBox(width: 8),
              ..._images.asMap().entries.map((entry) {
                int idx = entry.key;
                XFile image = entry.value;
                return Stack(
                  children: [
                    Image.file(
                      File(image.path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _removeImage(idx),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text('원 (WON)'),
          selected: _currency == 'WON',
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _currency = 'WON';
              });
            }
          },
        ),
        const SizedBox(width: 16.0),
        ChoiceChip(
          label: const Text('엔 (YEN)'),
          selected: _currency == 'YEN',
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _currency = 'YEN';
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return TextFormField(
      controller: _categoryController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: '카테고리',
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      onTap: () => _showCategoryDialog(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '카테고리를 선택하세요.';
        }
        return null;
      },
    );
  }

  Widget _buildPayerSelector() {
    return TextFormField(
      controller: _payerController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: '결제자',
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      onTap: () => _showPayerDialog(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '결제자를 선택하세요.';
        }
        return null;
      },
    );
  }

  void _showPayerDialog() async {
    final selectedUser = await showDialog<TravelUserDetailResponse>(
      context: context,
      builder: (context) => PaymentUserDialog(travelId: widget.travelId),
    );

    if (selectedUser != null) {
      setState(() {
        _payerController.text = selectedUser.travelNickName;
        _selectedPayerTravelUserId = selectedUser.travelUserId;
      });
    }
  }

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
                final state = ref.watch(categoryProvider("PREPAYMENT"));
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
                              setState(() {
                                _categoryController.text =
                                    category.categoryName;
                                _selectedCategoryId = category.categoryId;
                              });
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

  Widget _buildSettlementUserSelector() {
    return TextFormField(
      controller: _settlementUsersController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: '정산에 포함될 사람 (파란색 체크: 사전 정산 완료)',
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      onTap: _showSettlementUserDialog,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '정산에 포함될 사람을 선택하세요.';
        }
        return null;
      },
    );
  }

  void _showSettlementUserDialog() async {
    final result = await showDialog<List<SettlementParticipantDto>>(
      context: context,
      builder: (context) => SettlementUserDialog(
        travelId: widget.travelId,
        initialParticipants: _settlementParticipants,
        showPaidCheckBox: true,
      ),
    );

    if (result != null) {
      setState(() {
        _settlementParticipants = result;
        _settlementUsersController.text =
            result.map((e) => e.travelNickName).join(', ');
      });
    }
  }
}
