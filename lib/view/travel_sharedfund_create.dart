import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';

import '../data/notifier/travel_list_notifier.dart';

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

  // ▼ 통화 상태: nation에 따라 기본값 지정
  late String _currencyCode; // 'YEN' | 'WON'
  String get _currencyLabel => _currencyCode == 'YEN' ? '엔' : '원';

  @override
  void initState() {
    super.initState();

    // 날짜 초기화
    final initialDate = ref.read(dateNotifierProvider) ?? DateTime.now();
    final now = DateTime.now();
    _selectedDateTime = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
      now.hour,
      now.minute,
    );

    // 여행의 nation으로 기본 통화 설정
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    final nation = travel?.nation.toUpperCase() ?? '';
    _currencyCode = (nation == 'JAPAN') ? 'YEN' : 'WON';
  }

  @override
  void dispose() {
    _payerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _saveSharedFund() async {
    if (!_formKey.currentState!.validate()) return;

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

      final travelUsers = users
          .map(
            (u) => SettlementParticipantRequestDto(
              travelUserId: u.travelUserId,
              isPaid: false,
            ),
          )
          .toList();
      final amount = int.parse(_amountController.text);

      // ✅ 사람 기준 정산 상태(공금 입금이므로 기본은 모두 미정산 false)
      final participants = travelUserIds
          .map((id) => SettlementParticipant(travelUserId: id, isPaid: false))
          .toList();

      final request = PaymentRequest(
        paymentId: null, // 생성이므로 null, 수정 시에만 세팅
        travelId: widget.travelId,
        travelUserId: _selectedPayerTravelUserId,
        categoryId: 1, // 공금 입금 전용 카테고리(도메인에 맞게 유지)
        payerType: 'INDIVIDUAL', // 입금자는 개인
        payTime: _selectedDateTime.toIso8601String(),
        paymentMethod: _paymentMethod,
        paymentName: '공금 입금',
        paymentType: widget.paymentType, // 예: "SHAREDFUND"
        currency: _currencyCode, // ★ 여행 국가 통화
        paymentAccount: amount,
        settlementList: [
          Settlement(
            settlementName: '공금 입금',
            amount: amount,
            travelUsers: participants,
          ),
        ],
      );

      await ref
          .read(paymentNotifierProvider.notifier)
          .createPayment(request, const <File>[]);
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
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('공금 기록'), scrolledUnderElevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 안내 배너
                _InfoBanner(
                  icon: Icons.info_outline,
                  text:
                      '공금 입금은 해당 여행의 국가 통화로 충전됩니다. '
                      '이번 여행은 $_currencyLabel 기준으로 관리됩니다.',
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    children: [
                      // 입금자 섹션
                      _SectionCard(title: '입금자', child: _buildPayerSelector()),
                      const SizedBox(height: 12),

                      // 금액 섹션 (통화 라벨 표시)
                      _SectionCard(
                        title: '금액 ($_currencyLabel)',
                        child: TextFormField(
                          controller: _amountController,
                          decoration: InputDecoration(
                            labelText: '금액',
                            hintText: '숫자만 입력',
                            suffix: Text(
                              _currencyLabel,
                              style: t.bodyMedium?.copyWith(
                                color: c.onSurfaceVariant,
                              ),
                            ),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            signed: false,
                            decimal: false,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            if (v == null || v.isEmpty) return '금액을 입력하세요.';
                            final parsed = int.tryParse(v);
                            if (parsed == null || parsed <= 0) {
                              return '올바른 금액을 입력하세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 결제 방식 섹션
                      _SectionCard(
                        title: '결제 방식',
                        child: _buildPaymentMethodSelector(),
                      ),
                      const SizedBox(height: 12),

                      // 시간 섹션
                      _SectionCard(title: '시간', child: _buildTimePicker()),
                    ],
                  ),
                ),

                // 저장 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: paymentState.createStatus == Status.loading
                        ? null
                        : _saveSharedFund,
                    icon: paymentState.createStatus == Status.loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('저장'),
                    style: FilledButton.styleFrom(
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildPayerSelector() {
    return TextFormField(
      controller: _payerController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: '입금자',
        hintText: '입금자 선택',
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      onTap: _showPayerDialog,
      validator: (value) =>
          (value == null || value.isEmpty) ? '입금자를 선택하세요.' : null,
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
          .map((e) => DropdownMenuItem(value: e.value, child: Text(e.key)))
          .toList(),
      onChanged: (v) => setState(() => _paymentMethod = v ?? 'CASH'),
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '선택된 시간',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          DateFormat('yyyy.MM.dd a hh:mm', 'ko_KR').format(_selectedDateTime),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
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

// --- 재사용 작은 위젯들 ---

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.primary.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.primary.withOpacity(.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: c.onSurface, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
