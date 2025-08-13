// lib/view/travel_sharedfund_update_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/dialog/payment_user_dialog.dart';
import 'package:yoen_front/data/model/payment_create_request.dart'; // Settlement/SettlementParticipant
import 'package:yoen_front/data/model/payment_image_response.dart';
import 'package:yoen_front/data/model/payment_update_request.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';

import '../data/enums/status.dart';

class TravelSharedfundUpdateScreen extends ConsumerStatefulWidget {
  final int travelId;
  final int paymentId; // 수정 대상 결제
  const TravelSharedfundUpdateScreen({
    super.key,
    required this.travelId,
    required this.paymentId,
  });

  @override
  ConsumerState<TravelSharedfundUpdateScreen> createState() =>
      _TravelSharedfundUpdateScreenState();
}

class _TravelSharedfundUpdateScreenState
    extends ConsumerState<TravelSharedfundUpdateScreen> {
  final _formKey = GlobalKey<FormState>();

  final _payerController = TextEditingController();
  final _amountController = TextEditingController();

  int? _travelUserId;
  String _paymentMethod = 'CASH';
  DateTime? _selectedDateTime;

  // 통화
  String _currencyCode = 'WON'; // 서버 값 사용, 없으면 여행국가로 폴백
  String get _currencyLabel => _currencyCode == 'YEN' ? '엔' : '원';

  // 이미지
  final Set<int> _removedImageIds = {};
  final List<XFile> _newImages = [];
  List<PaymentImageResponse> _serverImages = [];

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // 상세 조회
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _hydrateFromState();
    });
  }

  void _hydrateFromState() {
    final s = ref.read(paymentNotifierProvider).selectedPayment;
    if (s == null) return;

    // 통화: 우선 서버값, 없으면 여행 국가로 폴백
    String? cur = (s.currency ?? '').toUpperCase();
    if (cur != 'YEN' && cur != 'WON') {
      final nation =
          ref.read(travelListNotifierProvider).selectedTravel?.nation ??
          'KOREA';
      cur = (nation == 'JAPAN') ? 'YEN' : 'WON';
    }
    _currencyCode = cur!;

    // 금액/결제자/시간/결제방식
    _amountController.text = (s.paymentAccount ?? 0).toString();
    _payerController.text = s.payerName?.travelNickname ?? '';
    _travelUserId = s.payerName?.travelUserId;
    _paymentMethod = (s.paymentMethod?.toUpperCase() ?? 'CASH');
    try {
      if (s.payTime != null && s.payTime!.isNotEmpty) {
        final dt = DateTime.parse(s.payTime!);
        _selectedDateTime = dt.isUtc ? dt.toLocal() : dt;
      }
    } catch (_) {
      _selectedDateTime ??= DateTime.now();
    }
    _selectedDateTime ??= DateTime.now();

    // 서버 이미지
    _serverImages = (s.images ?? const []);

    setState(() {
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _payerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickNewImages() async {
    FocusScope.of(context).unfocus();
    final picker = ImagePicker();

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('앨범에서 선택'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
          ],
        ),
      ),
    );

    if (action == 'gallery') {
      final files = await picker.pickMultiImage();
      if (files.isNotEmpty) setState(() => _newImages.addAll(files));
    } else if (action == 'camera') {
      final file = await picker.pickImage(source: ImageSource.camera);
      if (file != null) setState(() => _newImages.add(file));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final selected = ref.read(paymentNotifierProvider).selectedPayment;
    if (selected == null) return;

    // 참여자 전원 가져와서 "공금 입금" 참여자(모두 isPaid=false) 구성
    final api = ref.read(apiServiceProvider);
    final res = await api.getTravelUsers(widget.travelId);
    final users = res.data ?? [];
    if (users.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('여행 참여자 정보를 불러올 수 없습니다.')));
      return;
    }
    final participants = users
        .map(
          (u) => SettlementParticipant(
            travelUserId: u.travelUserId,
            isPaid: false,
          ),
        )
        .toList();

    final amount = int.tryParse(_amountController.text) ?? 0;

    final req = PaymentUpdateRequest(
      paymentId: selected.paymentId!,
      travelId: widget.travelId,
      paymentType: 'SHAREDFUND', // 공금 충전
      paymentName: selected.paymentName ?? '공금 입금',
      paymentMethod: _paymentMethod,
      payerType: 'INDIVIDUAL', // 입금자는 개인
      categoryId: selected.categoryId ?? 1, // 프로젝트 정책대로 유지
      travelUserId: _travelUserId,
      payTime: _selectedDateTime!.toIso8601String(),
      paymentAccount: amount,
      currency: _currencyCode,
      settlementList: [
        Settlement(
          settlementName: '공금 입금',
          amount: amount,
          travelUsers: participants,
        ),
      ],
      removeImageIds: _removedImageIds.toList(),
    );

    final newFiles = _newImages.map((x) => File(x.path)).toList();

    await ref
        .read(paymentNotifierProvider.notifier)
        .updatePayment(req, newFiles);
  }

  String _fmt(DateTime dt) =>
      DateFormat('yyyy.MM.dd a hh:mm', 'ko_KR').format(dt);

  @override
  Widget build(BuildContext context) {
    ref.listen<PaymentState>(paymentNotifierProvider, (prev, next) {
      if (prev?.updateStatus != next.updateStatus) {
        if (next.updateStatus == Status.success) {
          Navigator.of(context).pop(true);
        } else if (next.updateStatus == Status.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.errorMessage ?? '수정에 실패했습니다.')),
          );
        }
      }
      // 상세 재조회 중 로딩/에러 처리
      if (prev?.getDetailsStatus != next.getDetailsStatus) {
        if (next.getDetailsStatus == Status.success && !_initialized) {
          _hydrateFromState();
        }
      }
    });

    final state = ref.watch(paymentNotifierProvider);
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // 상세 미로딩 시
    if (state.getDetailsStatus == Status.loading || !_initialized) {
      if (state.getDetailsStatus == Status.error) {
        return Scaffold(
          appBar: AppBar(title: const Text('공금 기록 수정')),
          body: Center(
            child: Text(
              state.errorMessage ?? '상세 정보를 불러오지 못했습니다.',
              style: TextStyle(color: c.error),
            ),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: const Text('공금 기록 수정')),
        body: const Center(child: ProgressBadge(label: "불러오는 중")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('공금 기록 수정'), scrolledUnderElevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _InfoBanner(
                  icon: Icons.info_outline,
                  text:
                      '공금 입금은 해당 여행의 국가 통화로 관리됩니다. '
                      '현재 통화: $_currencyLabel',
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: ListView(
                    children: [
                      _SectionCard(title: '입금자', child: _buildPayerSelector()),
                      const SizedBox(height: 12),

                      _SectionCard(
                        title: '금액 ($_currencyLabel)',
                        child: TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: '금액',
                            hintText: '숫자만 입력',
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

                      _SectionCard(
                        title: '결제 방식',
                        child: _buildPaymentMethodSelector(),
                      ),
                      const SizedBox(height: 12),

                      _SectionCard(title: '시간', child: _buildTimePicker()),
                    ],
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: state.updateStatus == Status.loading
                        ? null
                        : _save,
                    icon: state.updateStatus == Status.loading
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

  // --- UI builders ---

  Widget _buildPayerSelector() {
    return TextFormField(
      controller: _payerController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: '입금자',
        hintText: '입금자 선택',
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        final selected = await showDialog<TravelUserDetailResponse>(
          context: context,
          builder: (context) => PaymentUserDialog(travelId: widget.travelId),
        );
        if (selected != null) {
          setState(() {
            _payerController.text = selected.travelNickname;
            _travelUserId = selected.travelUserId;
          });
        }
      },
      validator: (value) =>
          (value == null || value.isEmpty) ? '입금자를 선택하세요.' : null,
    );
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
    final dt = _selectedDateTime ?? DateTime.now();
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
          _fmt(dt),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(dt),
        );
        if (time != null) {
          setState(() {
            _selectedDateTime = DateTime(
              dt.year,
              dt.month,
              dt.day,
              time.hour,
              time.minute,
            );
          });
        }
      },
    );
  }
}

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
