import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/dialog/settlement_user_dialog.dart';
import 'package:yoen_front/data/model/category_response.dart';
import 'package:yoen_front/data/notifier/category_notifier.dart';
import 'package:flutter/material.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';

class SettlementItem {
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  bool isPaid = false;
  List<int> travelUserIds = [];
  List<String> travelUserNames = [];
}

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
  late DateTime _selectedDate;
  String _paymentMethod = 'CARD';
  String _payerType = 'INDIVIDUAL'; // INDIVIDUAL or SHAREDFUND
  int? _selectedCategoryId;
  int? _selectedPayerTravelUserId;
  List<SettlementItem> _settlementItems = [SettlementItem()];
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  final Map<String, String> _paymentMethodMap = {
    '카드': 'CARD',
    '현금': 'CASH',
    '트레블카드': 'TRAVELCARD',
  };

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    setState(() {
      _images.addAll(pickedFiles);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = ref.read(dateNotifierProvider) ?? DateTime.now();
    final now = DateTime.now();
    _selectedTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentState = ref.watch(paymentNotifierProvider);

    ref.listen<PaymentState>(paymentNotifierProvider, (previous, next) {
      if (next.createStatus == Status.success) {
        Navigator.of(context).pop(true);
      } else if (next.createStatus == Status.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage ?? '오류가 발생했습니다.')));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('결제 내역 추가'),
        actions: [
          if (paymentState.createStatus == Status.loading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircularProgressIndicator(),
            )
          else
            IconButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final settlementList = _settlementItems.map((item) {
                    return Settlement(
                      settlementName: item.nameController.text,
                      amount: int.parse(item.amountController.text),
                      isPaid: item.isPaid,
                      travelUsers: item.travelUserIds,
                    );
                  }).toList();

                  final totalAmount = settlementList.fold<int>(
                    0,
                    (sum, item) => sum + item.amount,
                  );

                  final payTime = DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  );

                  final request = PaymentCreateRequest(
                    travelId: widget.travelId,
                    travelUserId: _payerType == 'INDIVIDUAL'
                        ? _selectedPayerTravelUserId
                        : null,
                    categoryId: _selectedCategoryId!,
                    payerType: _payerType,
                    payTime: payTime.toIso8601String(),
                    paymentName: _paymentNameController.text,
                    paymentMethod: _paymentMethod,
                    paymentType: widget.paymentType,
                    paymentAccount: totalAmount,
                    settlementList: settlementList,
                  );

                  final imageFiles = _images
                      .map((image) => File(image.path))
                      .toList();

                  await ref
                      .read(paymentNotifierProvider.notifier)
                      .createPayment(request, imageFiles);
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
              _buildPayerTypeSelector(),
              const SizedBox(height: 16.0),
              _buildTimePicker(),
              const SizedBox(height: 16.0),
              if (_payerType == 'INDIVIDUAL') ...[
                _buildPayerSelector(),
                const SizedBox(height: 16.0),
              ],
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
              _buildSettlementList(),
              const SizedBox(height: 16.0),
              _buildImagePicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPayerTypeSelector() {
    return SegmentedButton<String>(
      segments: const <ButtonSegment<String>>[
        ButtonSegment<String>(value: 'INDIVIDUAL', label: Text('개인')),
        ButtonSegment<String>(value: 'SHAREDFUND', label: Text('공금')),
      ],
      selected: {_payerType},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _payerType = newSelection.first;
        });
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
        if (_payerType == 'INDIVIDUAL' && (value == null || value.isEmpty)) {
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
      items: _paymentMethodMap.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.value, // 내부 값 (e.g. 'CARD')
              child: Text(entry.key), // UI에 보여질 텍스트 (e.g. '카드')
            ),
          )
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

  Widget _buildSettlementList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _settlementItems.length,
      itemBuilder: (context, index) {
        return _buildSettlementItem(index);
      },
    );
  }

  Widget _buildSettlementItem(int index) {
    final item = _settlementItems[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: item.nameController,
              decoration: const InputDecoration(labelText: '결제 내역 이름'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '내역 이름을 입력하세요.';
                }
                return null;
              },
            ),
            TextFormField(
              controller: item.amountController,
              decoration: const InputDecoration(labelText: '금액'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '금액을 입력하세요.';
                }
                return null;
              },
            ),
            CheckboxListTile(
              title: const Text('정산 여부'),
              value: item.isPaid,
              onChanged: (bool? value) {
                setState(() {
                  item.isPaid = value ?? false;
                });
              },
            ),
            ListTile(
              title: const Text('참여 유저'),
              subtitle: Text(item.travelUserNames.join(', ')),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                final selectedUsers =
                    await showDialog<List<TravelUserDetailResponse>>(
                      context: context,
                      builder: (context) =>
                          SettlementUserDialog(travelId: widget.travelId),
                    );
                if (selectedUsers != null) {
                  setState(() {
                    item.travelUserIds = selectedUsers
                        .map((e) => e.travelUserId)
                        .toList();
                    item.travelUserNames = selectedUsers
                        .map((e) => e.travelNickName)
                        .toList();
                  });
                }
              },
            ),
            if (index > 0)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () {
                  setState(() {
                    _settlementItems.removeAt(index);
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('사진'),
        const SizedBox(height: 8.0),
        GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _pickImages();
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
          itemCount: _images.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Image.file(
                  File(_images[index].path),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
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
