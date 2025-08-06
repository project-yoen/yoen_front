import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';

class TravelSharedfundCreateScreen extends ConsumerStatefulWidget {
  final int travelId;
  final String paymentType;
  const TravelSharedfundCreateScreen({
    super.key,
    required this.travelId,
    required this.paymentType,
  });

  @override
  ConsumerState<TravelSharedfundCreateScreen> createState() =>
      _TravelSharedfundCreateScreenState();
}

class _TravelSharedfundCreateScreenState
    extends ConsumerState<TravelSharedfundCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payerController = TextEditingController();
  final _amountController = TextEditingController();
  int? _selectedPayerTravelUserId;
  String _paymentMethod = 'CASH';
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    final initialDate = ref.read(dateNotifierProvider) ?? DateTime.now();
    final now = DateTime.now();
    _selectedDateTime = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      now.hour,
      now.minute,
    );
  }

  @override
  void dispose() {
    _payerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveSharedFund() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.getTravelUsers(widget.travelId);
      final users = response.data;

      if (users == null || users.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('여행 참여자 정보를 불러올 수 없습니다.')));
        return;
      }
      final travelUserIds = users.map((user) => user.travelUserId).toList();

      final request = PaymentCreateRequest(
        travelId: widget.travelId,
        travelUserId: _selectedPayerTravelUserId,
        categoryId: 1, // 공금 입금은 카테고리 없음
        payerType: 'INDIVIDUAL', // 입금자는 개인이므로
        payTime: _selectedDateTime.toIso8601String(),
        paymentMethod: _paymentMethod,
        paymentName: '공금 입금 [${_payerController.text}]', // 이름 기본값
        paymentType: widget.paymentType, // "SHAREDFUND"
        paymentAccount: int.parse(_amountController.text),
        settlementList: [
          Settlement(
            paymentId: null, // paymentId는 백엔드에서 생성되므로 null
            settlementName: "",
            amount: int.parse(_amountController.text),
            isPaid: false,
            travelUsers: travelUserIds,
          ),
        ],
      );

      await ref
          .read(paymentNotifierProvider.notifier)
          .createPayment(request, []);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentNotifierProvider, (previous, next) {
      if (next.createStatus == Status.success) {
        Navigator.of(context).pop(true);
      } else if (next.createStatus == Status.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '저장에 실패했습니다.')),
        );
      }
    });

    final paymentState = ref.watch(paymentNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('공금 기록')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildPayerSelector(),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(labelText: '금액'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '금액을 입력하세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    _buildPaymentMethodSelector(),
                    const SizedBox(height: 16.0),
                    _buildTimePicker(),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: paymentState.createStatus == Status.loading
                    ? null
                    : _saveSharedFund,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: paymentState.createStatus == Status.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('저장'),
              ),
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
        labelText: '입금자',
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      onTap: () => _showPayerDialog(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '입금자를 선택하세요.';
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

  Widget _buildPaymentMethodSelector() {
    final Map<String, String> paymentMethodMap = {
      '카드': 'CARD',
      '현금': 'CASH',
      '트레블카드': 'TRAVELCARD',
    };
    return DropdownButtonFormField<String>(
      value: _paymentMethod,
      decoration: const InputDecoration(labelText: '결제 방식'),
      items: paymentMethodMap.entries
          .map(
            (entry) =>
                DropdownMenuItem(value: entry.value, child: Text(entry.key)),
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

  Widget _buildTimePicker() {
    return ListTile(
      title: Text(
        '시간: ${DateFormat('yyyy.MM.dd a hh:mm', 'ko_KR').format(_selectedDateTime)}',
      ),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        );
        if (time != null) {
          setState(() {
            _selectedDateTime = DateTime(
              _selectedDateTime.year,
              _selectedDateTime.month,
              _selectedDateTime.day,
              time.hour,
              time.minute,
            );
          });
        }
      },
    );
  }
}
