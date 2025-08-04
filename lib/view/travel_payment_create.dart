import 'package:flutter/material.dart';

class TravelPaymentCreateScreen extends StatefulWidget {
  final String paymentType;
  const TravelPaymentCreateScreen({super.key, required this.paymentType});

  @override
  State<TravelPaymentCreateScreen> createState() =>
      _TravelPaymentCreateScreenState();
}

class _TravelPaymentCreateScreenState extends State<TravelPaymentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payerController = TextEditingController();
  final _paymentNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _memoController = TextEditingController();

  DateTime _selectedTime = DateTime.now();
  String _paymentMethod = '카드';

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
              TextFormField(
                controller: _payerController,
                decoration: const InputDecoration(labelText: '결제자'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '결제자를 입력하세요.';
                  }
                  return null;
                },
              ),
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
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: '카테고리'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '카테고리를 입력하세요.';
                  }
                  return null;
                },
              ),
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
