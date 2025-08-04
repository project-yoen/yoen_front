import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/model/category_response.dart';
import 'package:yoen_front/data/notifier/category_notifier.dart';
import 'package:flutter/material.dart';

import 'package:yoen_front/data/model/travel_user_detail_response.dart';

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
  final _payerController = TextEditingController();
  final _paymentNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _memoController = TextEditingController();

  DateTime _selectedTime = DateTime.now();
  String _paymentMethod = '카드';
  int? _selectedCategoryId;
  int? _selectedPayerTravelUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 내역 추가'),
        actions: [
          IconButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // TODO: API 연동
              }
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTimePicker(),
              const SizedBox(height: 16.0),
              _buildPayerSelector(),
              const SizedBox(height: 16.0),
              _buildPaymentMethodSelector(),
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
              _buildCategorySelector(),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(labelText: '결제 내역'),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              _buildImagePicker(),
            ],
          ),
        ),
      ),
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

  Widget _buildTimePicker() {
    return Row(
      children: [
        const Text('시간:'),
        const SizedBox(width: 16.0),
        TextButton(
          onPressed: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(_selectedTime),
            );
            if (time != null) {
              setState(() {
                _selectedTime = DateTime(
                  _selectedTime.year,
                  _selectedTime.month,
                  _selectedTime.day,
                  time.hour,
                  time.minute,
                );
              });
            }
          },
          child: Text(
            '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return DropdownButtonFormField<String>(
      value: _paymentMethod,
      decoration: const InputDecoration(labelText: '결제 방식'),
      items: ['카드', '현금']
          .map((method) => DropdownMenuItem(value: method, child: Text(method)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _paymentMethod = value;
          });
        }
      },
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
                              setState(() {
                                _categoryController.text = category.categoryName;
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('사진'),
        const SizedBox(height: 8.0),
        ElevatedButton(
          onPressed: () {
            // TODO: 이미지 선택 기능 구현
          },
          child: const Text('사진 선택'),
        ),
      ],
    );
  }
}
