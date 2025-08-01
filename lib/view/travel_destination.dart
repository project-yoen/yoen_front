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
  String _selectedCountry = 'KOREA'; // 초기 선택값 설정
  final TextEditingController _searchController = TextEditingController();
  final List<DestinationResponse> _selectedDestinations = [];

  // 검색 목록을 보여줄지 여부를 결정하는 상태
  bool _showDestinations = false;

  @override
  void initState() {
    super.initState();
  }

  void _fetchDestinationsByCountry() {
    ref
        .read(destinationNotifierProvider.notifier)
        .fetchDestinations(_selectedCountry);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinationState = ref.watch(destinationNotifierProvider);
    List<DestinationResponse> filteredDestinations = [];

    if (destinationState.status == DestinationStatus.success) {
      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isEmpty) {
        filteredDestinations = destinationState.destinations;
      } else {
        filteredDestinations = destinationState.destinations
            .where(
              (dest) =>
                  dest.destinationName.toLowerCase().contains(searchQuery),
            )
            .toList();
      }
    }

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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus(); // 키보드 숨기기
          setState(() {
            _showDestinations = false; // 목적지 목록 숨기기
          });
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: SegmentedButton<String>(
                          segments: const <ButtonSegment<String>>[
                            ButtonSegment<String>(
                              value: 'KOREA',
                              label: Text('한국'),
                            ),
                            ButtonSegment<String>(
                              value: 'JAPAN',
                              label: Text('일본'),
                            ),
                          ],
                          selected: {_selectedCountry},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _selectedCountry = newSelection.first;
                              _fetchDestinationsByCountry(); // 국가 변경 시 목적지 다시 로드
                              _showDestinations = true; // 목록을 바로 보여줌
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _searchController,
                        onTap: () {
                          // 텍스트 필드를 탭하면 API 호출 및 목록 표시
                          if (!_showDestinations) {
                            _fetchDestinationsByCountry();
                            setState(() {
                              _showDestinations = true;
                            });
                          }
                        },
                        onChanged: (value) {
                          // 검색어가 변경될 때마다 화면을 다시 그려서 목록을 필터링
                          setState(() {});
                        },
                        decoration: const InputDecoration(
                          hintText: '목적지를 검색하세요',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // _showDestinations가 true일 때만 목록을 보여줌
                      if (_showDestinations)
                        SizedBox(
                          height: 250,
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              borderRadius: const BorderRadius.all(
                                Radius.circular(12),
                              ),
                            ),
                            child: _buildDestinationList(
                              destinationState,
                              filteredDestinations,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (_selectedDestinations.isNotEmpty)
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _selectedDestinations
                              .map(
                                (dest) => Chip(
                                  label: Text(dest.destinationName),
                                  onDeleted: () {
                                    setState(() {
                                      _selectedDestinations.removeWhere(
                                        (d) =>
                                            d.destinationId ==
                                            dest.destinationId,
                                      );
                                    });
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40, bottom: 20),
                          child: FloatingActionButton(
                            onPressed: () {
                              if (_selectedDestinations.isNotEmpty) {
                                final destinationIds = _selectedDestinations
                                    .map((dest) => dest.destinationId)
                                    .toList();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TravelDetailScreen(
                                      nation: _selectedCountry,
                                      destinationIds: destinationIds,
                                    ),
                                  ),
                                );
                              } else {
                                // 목적지가 선택되지 않았을 때 사용자에게 알림
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('목적지를 하나 이상 선택해주세요.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                            child: const Icon(Icons.arrow_forward),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDestinationList(
    DestinationState state,
    List<DestinationResponse> filteredList,
  ) {
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
        if (filteredList.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다.'));
        }
        return ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final destination = filteredList[index];
            return ListTile(
              title: Text(destination.destinationName),
              onTap: () {
                _selectDestination(destination);
              },
            );
          },
        );
      case DestinationStatus.idle:
        return const Center(child: Text('목적지를 선택해주세요.'));
    }
  }

  void _selectDestination(DestinationResponse destination) {
    // 중복 추가 방지
    if (!_selectedDestinations.any(
      (d) => d.destinationId == destination.destinationId,
    )) {
      setState(() {
        _selectedDestinations.add(destination);
      });
    }
    setState(() {});
    _searchController.clear();
  }
}
