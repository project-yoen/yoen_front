import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/destination_response.dart';
import 'package:yoen_front/data/notifier/destination_notifier.dart';
import 'travel_detail.dart'; // TravelDetailScreen 임포트 추가

class TravelDestinationScreen extends ConsumerStatefulWidget {
  const TravelDestinationScreen({super.key});

  @override
  ConsumerState<TravelDestinationScreen> createState() =>
      _TravelDestinationScreenState();
}

class _TravelDestinationScreenState
    extends ConsumerState<TravelDestinationScreen> {
  Set<String> _selectedCountry = {'한국'}; // 초기 선택값 설정
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _destination1Controller = TextEditingController();
  final TextEditingController _destination2Controller = TextEditingController();

  // 검색 목록을 보여줄지 여부를 결정하는 상태
  bool _showDestinations = false;

  @override
  void dispose() {
    _searchController.dispose();
    _destination1Controller.dispose();
    _destination2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinationState = ref.watch(destinationNotifierProvider);

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
        title: const Text('목적지 입력'),
        centerTitle: false,
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
            const SizedBox(height: 20),
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
              controller: _searchController,
              onTap: () {
                // 텍스트 필드를 탭하면 API 호출 및 목록 표시
                ref
                    .read(destinationNotifierProvider.notifier)
                    .fetchDestinations();
                setState(() {
                  _showDestinations = true;
                });
              },
              decoration: const InputDecoration(
                hintText: '목적지를 검색하세요',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              readOnly: true, // 사용자가 직접 입력하는 것을 방지하고 탭 이벤트만 사용
            ),
            const SizedBox(height: 20),
            // _showDestinations가 true일 때만 목록을 보여줌
            if (_showDestinations)
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: _buildDestinationList(destinationState),
                ),
              ),
            if (!_showDestinations) ...[
              const SizedBox(height: 20),
              TextFormField(
                controller: _destination1Controller,
                decoration: const InputDecoration(
                  labelText: '목적지 1',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _destination2Controller,
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
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationList(DestinationState state) {
    switch (state.status) {
      case DestinationStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case DestinationStatus.error:
        return Center(
          child: Text(
            state.errorMessage ?? '오류가 발생했습니다.',
            style: const TextStyle(color: Colors.red),
          ),
        );
      case DestinationStatus.success:
        if (state.destinations.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다.'));
        }
        return ListView.builder(
          itemCount: state.destinations.length,
          itemBuilder: (context, index) {
            final destination = state.destinations[index];
            return ListTile(
              title: Text(destination.destinationName),
              subtitle: Text(destination.nation),
              onTap: () {
                _selectDestination(destination);
              },
            );
          },
        );
      case DestinationStatus.idle:
      default:
        return const Center(child: Text('목적지를 선택해주세요.'));
    }
  }

  void _selectDestination(DestinationResponse destination) {
    // 검색창에 선택한 목적지 이름을 표시
    _searchController.text = destination.destinationName;

    // 목적지 1 또는 2에 할당
    if (_destination1Controller.text.isEmpty) {
      _destination1Controller.text = destination.destinationName;
    } else if (_destination2Controller.text.isEmpty) {
      _destination2Controller.text = destination.destinationName;
    } else {
      _destination1Controller.text = destination.destinationName;
    }

    // 목록을 숨김
    setState(() {
      _showDestinations = false;
    });
    // 키보드 숨기기
    FocusScope.of(context).unfocus();
  }
}
