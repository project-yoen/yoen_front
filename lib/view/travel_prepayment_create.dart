import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/model/category_response.dart';
import 'package:yoen_front/data/notifier/category_notifier.dart';

import 'package:yoen_front/data/model/travel_user_detail_response.dart';

class TravelPrepaymentCreateScreen extends ConsumerStatefulWidget {
  final int travelId;
  final String paymentType;
  const TravelPrepaymentCreateScreen({
    super.key,
    required this.travelId,
    required this.paymentType,
  });

  @override
  ConsumerState<TravelPrepaymentCreateScreen> createState() =>
      _TravelPrepaymentCreateScreenState();
}

class _TravelPrepaymentCreateScreenState
    extends ConsumerState<TravelPrepaymentCreateScreen> {
  final _categoryController = TextEditingController();
  final _payerController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedPayerTravelUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사전사용금액 기록')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCategorySelector(),
            const SizedBox(height: 16.0),
            _buildPayerSelector(),
          ],
        ),
      ),
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
}
