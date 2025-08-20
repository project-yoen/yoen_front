import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';

class SettlementScreen extends ConsumerStatefulWidget {
  const SettlementScreen({super.key});

  @override
  ConsumerState<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends ConsumerState<SettlementScreen> {
  bool preUseAmount = true; // 사전 사용 금액
  bool sharedFund = true; // 공금
  bool recordedAmount = true; // 기록된 금액

  @override
  Widget build(BuildContext context) {
    final travel = ref.watch(travelListNotifierProvider).selectedTravel;

    if (travel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final c = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final startDate = DateTime.parse(travel.startDate);
    final endDate = DateTime.parse(travel.endDate);

    // 여행 마지막 날 23:59:59
    final periodHardEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );
    final now = DateTime.now();

    // 현재가 여행 범위 밖이면 여행 종료 시각으로 고정
    final periodEnd = (now.isBefore(startDate) || now.isAfter(periodHardEnd))
        ? periodHardEnd
        : now;

    final dateRange =
        "${DateFormat('yyyy.MM.dd HH:mm').format(startDate)} ~ ${DateFormat('yyyy.MM.dd HH:mm').format(periodEnd)}";

    final allOff = !preUseAmount && !sharedFund && !recordedAmount;

    return Scaffold(
      appBar: AppBar(title: const Text("정산하기")),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 헤더 카드
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: c.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "정산하기",
                      style: text.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 상태 배지
                    Row(
                      children: [
                        _Chip(
                          label: now.isBefore(startDate)
                              ? "여행 전"
                              : (now.isAfter(periodHardEnd) ? "여행 종료" : "여행 중"),
                          color: now.isBefore(startDate)
                              ? c.secondary
                              : (now.isAfter(periodHardEnd)
                                    ? c.tertiary
                                    : c.primary),
                        ),
                        const SizedBox(width: 8),
                        _Chip(label: travel.nation ?? "여행", color: c.secondary),
                      ],
                    ),

                    const SizedBox(height: 16),
                    Text(
                      "정산기간",
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "여행 첫날부터 현재 시간(또는 여행 종료 시점)까지",
                      style: text.bodySmall?.copyWith(
                        color: c.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 18,
                          color: c.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(dateRange, style: text.bodyMedium),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 정산 범위 카드 (스위치)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: c.outlineVariant),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      "정산 범위",
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "포함할 항목을 선택하세요.",
                      style: TextStyle(color: c.onSurfaceVariant),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    title: const Text("사전사용 금액"),
                    value: preUseAmount,
                    onChanged: (v) => setState(() => preUseAmount = v),
                    secondary: const Icon(Icons.event_available),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text("공금채운 금액"),
                    value: sharedFund,
                    onChanged: (v) => setState(() => sharedFund = v),
                    secondary: const Icon(
                      Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  SwitchListTile.adaptive(
                    title: const Text("기록된 금액"),
                    value: recordedAmount,
                    onChanged: (v) => setState(() => recordedAmount = v),
                    secondary: const Icon(Icons.receipt_long_outlined),
                  ),
                  if (allOff)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _HintBanner(
                        text: "최소 한 개 이상의 항목을 선택해야 정산을 진행할 수 있습니다.",
                        icon: Icons.info_outline,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 선택 요약
            _SelectionSummary(
              preUseAmount: preUseAmount,
              sharedFund: sharedFund,
              recordedAmount: recordedAmount,
            ),

            const SizedBox(height: 16),

            // CTA 버튼
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: allOff
                    ? null
                    : () {
                        // 선택 값으로 다음 단계 처리
                        debugPrint(
                          "정산 시작: $preUseAmount / $sharedFund / $recordedAmount",
                        );
                        // TODO: 다음 단계 내비게이션 연결
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("정산하기", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  final bool preUseAmount;
  final bool sharedFund;
  final bool recordedAmount;

  const _SelectionSummary({
    required this.preUseAmount,
    required this.sharedFund,
    required this.recordedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final chips = <Widget>[];
    if (preUseAmount) chips.add(_FilterChip(label: "사전사용", color: c.primary));
    if (sharedFund) chips.add(_FilterChip(label: "공금", color: c.secondary));
    if (recordedAmount) {
      chips.add(_FilterChip(label: "기록금액", color: c.tertiary));
    }

    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      firstChild: const SizedBox.shrink(),
      secondChild: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips.isEmpty
                ? [Text("선택 없음", style: TextStyle(color: c.onSurfaceVariant))]
                : chips,
          ),
        ),
      ),
      crossFadeState: chips.isEmpty
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: on, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FilterChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
    // onPrimary 안 쓰는 대신 보조 톤으로 표시 (읽기 쉬움)
  }
}

class _HintBanner extends StatelessWidget {
  final String text;
  final IconData icon;
  const _HintBanner({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: c.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.error.withOpacity(.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: c.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
