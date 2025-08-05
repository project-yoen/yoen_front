import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/dialog/settlement_user_dialog.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
import 'package:yoen_front/data/model/settlement_item.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/payment_create_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';

class TravelSettlementCreateScreen extends ConsumerStatefulWidget {
  final int travelId;
  final String paymentType;

  const TravelSettlementCreateScreen({
    super.key,
    required this.travelId,
    required this.paymentType,
  });

  @override
  ConsumerState<TravelSettlementCreateScreen> createState() =>
      _TravelSettlementCreateScreenState();
}

class _TravelSettlementCreateScreenState
    extends ConsumerState<TravelSettlementCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _listKey = GlobalKey<AnimatedListState>();

  Future<void> _savePayment(
    PaymentCreateState state,
    PaymentCreateNotifier notifier,
  ) async {
    if (_formKey.currentState!.validate()) {
      for (final item in state.settlementItems) {
        if (item.travelUserIds.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('각 정산 항목에 참여 유저를 선택해주세요.')),
          );
          return;
        }
      }
      final settlementList = state.settlementItems.map((item) {
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

      final request = PaymentCreateRequest(
        travelId: widget.travelId,
        travelUserId: state.payerTravelUserId,
        categoryId: state.categoryId!,
        payerType: state.payerType!,
        payTime: state.payTime!.toIso8601String(),
        paymentName: state.paymentName!,
        paymentMethod: state.paymentMethod!,
        paymentType: widget.paymentType,
        paymentAccount: totalAmount,
        settlementList: settlementList,
      );

      final imageFiles = state.images.map((image) => File(image.path)).toList();

      await ref
          .read(paymentNotifierProvider.notifier)
          .createPayment(request, imageFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentNotifierProvider, (previous, next) {
      if (next.createStatus == Status.success) {
        Navigator.of(context).pop(true);
      } else if (next.createStatus == Status.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '오류가 발생했습니다.')),
        );
      }
    });

    final paymentCreateState = ref.watch(paymentCreateNotifierProvider);
    final paymentCreateNotifier = ref.read(
      paymentCreateNotifierProvider.notifier,
    );
    final paymentState = ref.watch(paymentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('정산 내역 추가'),
        actions: [
          if (paymentState.createStatus == Status.loading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircularProgressIndicator(),
            )
          else
            IconButton(
              onPressed: () =>
                  _savePayment(paymentCreateState, paymentCreateNotifier),
              icon: const Icon(Icons.check),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: AnimatedList(
                  key: _listKey,
                  initialItemCount: paymentCreateState.settlementItems.length,
                  itemBuilder: (context, index, animation) {
                    return _buildAnimatedSettlementItem(
                      paymentCreateState.settlementItems[index],
                      animation,
                      index,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () =>
                    paymentCreateNotifier.addSettlementItem(_listKey),
                icon: const Icon(Icons.add),
                label: const Text('정산 항목 추가'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSettlementItem(
    SettlementItem item,
    Animation<double> animation,
    int index,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: _buildSettlementItem(item, index),
    );
  }

  Widget _buildSettlementItem(SettlementItem item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '정산 항목 ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (ref
                        .read(paymentCreateNotifierProvider)
                        .settlementItems
                        .length >
                    1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => ref
                        .read(paymentCreateNotifierProvider.notifier)
                        .removeSettlementItem(
                          index,
                          _listKey,
                          _buildAnimatedSettlementItem,
                        ),
                  ),
              ],
            ),
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
                      builder: (context) => SettlementUserDialog(
                        travelId: widget.travelId,
                        initialSelectedUserIds: item.travelUserIds,
                      ),
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
          ],
        ),
      ),
    );
  }
}
