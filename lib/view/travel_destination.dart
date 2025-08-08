import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/destination_response.dart';
import 'package:yoen_front/data/notifier/destination_notifier.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';
import 'travel_detail.dart';

class TravelDestinationScreen extends ConsumerStatefulWidget {
  const TravelDestinationScreen({super.key});

  @override
  ConsumerState<TravelDestinationScreen> createState() =>
      _TravelDestinationScreenState();
}

class _TravelDestinationScreenState
    extends ConsumerState<TravelDestinationScreen> {
  String _selectedCountry = 'KOREA';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode(); // 키보드/포커스 제어
  final List<DestinationResponse> _selectedDestinations = [];

  bool _showDestinations = false;
  bool _typingMode = false; // ← 버튼으로만 키보드 열기
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      // 포커스가 빠지면 타이핑 모드 해제 → 다시 readOnly로
      if (!_searchFocus.hasFocus && _typingMode) {
        setState(() => _typingMode = false);
      }
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _fetchDestinationsByCountry() {
    ref
        .read(destinationNotifierProvider.notifier)
        .fetchDestinations(_selectedCountry);
  }

  void _selectDestination(DestinationResponse destination) {
    if (!_selectedDestinations.any(
      (d) => d.destinationId == destination.destinationId,
    )) {
      setState(() {
        _selectedDestinations.add(destination);
      });
    }
    _searchController.clear();
  }

  void _removeDestination(DestinationResponse destination) {
    setState(() {
      _selectedDestinations.removeWhere(
        (d) => d.destinationId == destination.destinationId,
      );
    });
  }

  void _enterTypingMode() {
    if (_typingMode) return;
    setState(() => _typingMode = true);
    // 다음 프레임에 포커스 주기(키보드 표시)
    Future.microtask(() => _searchFocus.requestFocus());
  }

  void _exitTypingMode() {
    if (!_typingMode) return;
    _searchFocus.unfocus();
    setState(() => _typingMode = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(destinationNotifierProvider);
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // 필터링
    List<DestinationResponse> filtered = [];
    if (state.status == DestinationStatus.success) {
      final q = _searchController.text.trim().toLowerCase();
      filtered = q.isEmpty
          ? state.destinations
          : state.destinations
                .where((d) => d.destinationName.toLowerCase().contains(q))
                .toList();
    }

    final canProceed = _selectedDestinations.isNotEmpty;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        forceMaterialTransparency: true,
        scrolledUnderElevation: 0,
        title: const Text('목적지 입력'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // 키보드 토글 버튼
          IconButton(
            tooltip: _typingMode ? '키보드 닫기' : '검색에 포커스',
            onPressed: () {
              _typingMode ? _exitTypingMode() : _enterTypingMode();
            },
            icon: Icon(
              _typingMode ? Icons.keyboard_hide : Icons.keyboard_alt_outlined,
            ),
          ),
          IconButton(
            tooltip: '선택 초기화',
            onPressed: _selectedDestinations.isEmpty
                ? null
                : () => setState(_selectedDestinations.clear),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() => _showDestinations = false);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedPadding(
              // 키보드가 올라오면 FAB와 겹치지 않게 하단 여백 자동 조절
              padding: EdgeInsets.only(bottom: 100 + viewInsets.bottom),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag, // 드래그 시 키보드 닫힘
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 나라 토글
                      Center(
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: 'KOREA',
                              label: Text('한국'),
                              icon: Icon(Icons.flag),
                            ),
                            ButtonSegment(
                              value: 'JAPAN',
                              label: Text('일본'),
                              icon: Icon(Icons.flag_outlined),
                            ),
                          ],
                          selected: {_selectedCountry},
                          onSelectionChanged: (sel) {
                            setState(() {
                              _selectedCountry = sel.first;
                              _fetchDestinationsByCountry();
                              _showDestinations = true;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 안내 문구
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.primary.withOpacity(.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.primary.withOpacity(.18)),
                        ),
                        child: Text(
                          '여행할 나라를 먼저 선택하고, 목적지를 검색하여 추가하세요. '
                          '여러 목적지를 선택할 수 있습니다.',
                          style: t.bodyMedium?.copyWith(
                            color: c.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 검색 필드 (탭해도 키보드 안 뜸 — 버튼으로만 열기)
                      TextField(
                        focusNode: _searchFocus,
                        controller: _searchController,
                        readOnly: !_typingMode, // ← 핵심
                        onTap: () {
                          // 탭 시엔 목록만 보여주고, 키보드는 열지 않음
                          if (!_showDestinations) {
                            _fetchDestinationsByCountry();
                            setState(() => _showDestinations = true);
                          }
                        },
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: '목적지를 검색하세요',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchController.text.isNotEmpty)
                                IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                  tooltip: '지우기',
                                ),
                              IconButton(
                                onPressed: () {
                                  _typingMode
                                      ? _exitTypingMode()
                                      : _enterTypingMode();
                                },
                                icon: Icon(
                                  _typingMode
                                      ? Icons.keyboard_hide
                                      : Icons.keyboard_alt_outlined,
                                ),
                                tooltip: _typingMode ? '키보드 닫기' : '키보드 띄우기',
                              ),
                            ],
                          ),
                          filled: true,
                          fillColor: c.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 검색 결과 (애니메이션 + Card)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: !_showDestinations
                            ? const SizedBox.shrink()
                            : Card(
                                key: const ValueKey('destList'),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(color: c.outline),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SizedBox(
                                  height: 280,
                                  child: _buildDestinationList(
                                    context,
                                    state,
                                    filtered,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // 선택된 목적지 Chip들
                      if (_selectedDestinations.isNotEmpty) ...[
                        Text(
                          '선택된 목적지',
                          style: t.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedDestinations.map((d) {
                            return Chip(
                              label: Text(d.destinationName),
                              onDeleted: () => _removeDestination(d),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // 개선된 FAB: 확장형 + 상태 반영 + 바텀 세이프영역
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: canProceed
                ? () {
                    final ids = _selectedDestinations
                        .map((d) => d.destinationId)
                        .toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TravelDetailScreen(
                          nation: _selectedCountry,
                          destinationIds: ids,
                        ),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              canProceed
                  ? '다음 (${_selectedDestinations.length})'
                  : '목적지를 선택하세요',
            ),
            backgroundColor: canProceed ? c.primary : c.surfaceVariant,
            foregroundColor: canProceed ? c.onPrimary : c.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 3,
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationList(
    BuildContext context,
    DestinationState state,
    List<DestinationResponse> list,
  ) {
    final c = Theme.of(context).colorScheme;

    switch (state.status) {
      case DestinationStatus.loading:
        return const Center(child: ProgressBadge(label: "로딩 중"));
      case DestinationStatus.error:
        return Center(
          child: Text(
            state.errorMessage ?? '오류가 발생했습니다.',
            style: const TextStyle(color: Colors.red),
          ),
        );
      case DestinationStatus.idle:
        return const Center(child: Text('목적지를 선택해주세요.'));
      case DestinationStatus.success:
        if (list.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다.'));
        }
        return ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: c.outlineVariant),
          itemBuilder: (_, i) {
            final d = list[i];
            final already = _selectedDestinations.any(
              (x) => x.destinationId == d.destinationId,
            );
            return ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(d.destinationName),
              trailing: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: already
                    ? Icon(
                        Icons.check_circle,
                        color: c.primary,
                        key: const ValueKey('check'),
                      )
                    : Icon(
                        Icons.add_circle_outline,
                        color: c.onSurfaceVariant,
                        key: const ValueKey('add'),
                      ),
              ),
              onTap: () => _selectDestination(d),
            );
          },
        );
    }
  }
}
