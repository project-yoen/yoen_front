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

    final startDate = DateTime.parse(travel.startDate);
    final endDate = DateTime.parse(travel.endDate);

    // 자정(00:00)으로 맞춘 endDate
    final endDateMidnight = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
    );

    final now = DateTime.now();

    DateTime periodEnd;

    // 현재 시간이 여행 기간 밖이면 endDate 자정으로
    if (now.isBefore(startDate) || now.isAfter(endDate)) {
      periodEnd = endDateMidnight;
    } else {
      periodEnd = now;
    }

    final dateRange =
        "${DateFormat('yyyy.MM.dd HH:mm').format(startDate)} ~ ${DateFormat('yyyy.MM.dd HH:mm').format(periodEnd)}";
    return Scaffold(
      appBar: AppBar(
        title: const Text("정산하기"),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    "1",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 정산기간
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "정산하기",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "정산기간",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text("여행 첫날부터 현재시간까지"),
                  Text(dateRange, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  const Text(
                    "정산 범위",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  CheckboxListTile(
                    value: preUseAmount,
                    title: const Text("사전사용 금액"),
                    onChanged: (value) =>
                        setState(() => preUseAmount = value ?? false),
                  ),
                  CheckboxListTile(
                    value: sharedFund,
                    title: const Text("공금채운 금액"),
                    onChanged: (value) =>
                        setState(() => sharedFund = value ?? false),
                  ),
                  CheckboxListTile(
                    value: recordedAmount,
                    title: const Text("기록된 금액"),
                    onChanged: (value) =>
                        setState(() => recordedAmount = value ?? false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // 선택된 값으로 다음 단계 처리
                  debugPrint(
                    "정산 시작: $preUseAmount / $sharedFund / $recordedAmount",
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("정산하기", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
