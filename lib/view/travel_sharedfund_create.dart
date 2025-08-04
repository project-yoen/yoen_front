import 'package:flutter/material.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';

import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/notifier/travel_notifier.dart';

class TravelSharedfundCreateScreen extends StatefulWidget {
  final int travelId;
  final String paymentType;
  const TravelSharedfundCreateScreen({
    super.key,
    required this.travelId,
    required this.paymentType,
  });

  @override
  State<TravelSharedfundCreateScreen> createState() =>
      _TravelSharedfundCreateScreenState();
}

class _TravelSharedfundCreateScreenState
    extends State<TravelSharedfundCreateScreen> {
  final _payerController = TextEditingController();
  int? _selectedPayerTravelUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('공금 기록')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [_buildPayerSelector()]),
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
}
