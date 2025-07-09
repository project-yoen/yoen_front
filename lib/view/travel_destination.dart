import 'package:flutter/material.dart';
import 'travel_detail.dart'; // TravelDetailScreen 임포트 추가

class TravelDestinationScreen extends StatefulWidget {
  const TravelDestinationScreen({super.key});

  @override
  State<TravelDestinationScreen> createState() =>
      _TravelDestinationScreenState();
}

class _TravelDestinationScreenState extends State<TravelDestinationScreen> {
  Set<String> _selectedCountry = {'한국'}; // 초기 선택값 설정

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('목적지 입력'), // 제목 변경
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: 알림 확인 기능
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: SegmentedButton<String>(
                segments: const <ButtonSegment<String>>[
                  ButtonSegment<String>(value: '한국', label: Text('한국')),
                  ButtonSegment<String>(value: '일본', label: Text('일본')),
                ],
                selected: _selectedCountry,
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedCountry = newSelection;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '검색',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '목적지 1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              decoration: const InputDecoration(
                labelText: '목적지 2',
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.center,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TravelDetailScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.arrow_forward),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
