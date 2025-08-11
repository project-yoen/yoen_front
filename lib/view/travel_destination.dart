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
  final FocusNode _searchFocus = FocusNode();
  final List<DestinationResponse> _selectedDestinations = [];

  bool _typingMode = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus && _typingMode) {
        setState(() => _typingMode = false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(destinationNotifierProvider.notifier)
          .fetchDestinations(_selectedCountry);
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _fetchDestinationsByCountry() {
    ref
        .read(destinationNotifierProvider.notifier)
        .fetchDestinations(_selectedCountry);
  }

  void _toggleDestination(DestinationResponse d) {
    setState(() {
      final i = _selectedDestinations.indexWhere(
        (x) => x.destinationId == d.destinationId,
      );
      if (i >= 0) {
        _selectedDestinations.removeAt(i);
      } else {
        _selectedDestinations.add(d);
      }
    });
  }

  void _removeDestination(DestinationResponse d) {
    setState(() {
      _selectedDestinations.removeWhere(
        (x) => x.destinationId == d.destinationId,
      );
    });
  }

  void _enterTypingMode() {
    if (_typingMode) return;
    setState(() => _typingMode = true);
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

    final view = MediaQuery.of(context);
    final keyboardOpen = view.viewInsets.bottom > 0;

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

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('목적지 입력'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: _typingMode ? '키보드 닫기' : '검색에 포커스',
            onPressed: () =>
                _typingMode ? _exitTypingMode() : _enterTypingMode(),
            icon: Icon(
              _typingMode ? Icons.keyboard_hide : Icons.keyboard_alt_outlined,
            ),
          ),
          IconButton(
            tooltip: '선택 초기화',
            onPressed: _selectedDestinations.isEmpty
                ? null
                : () => setState(() => _selectedDestinations.clear()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: LayoutBuilder(
              builder: (ctx, cons) {
                // ---- 고정형 리스트 높이 정책 ----
                // 기본: 화면 높이의 0.38 ~ 0.42 사이, 최소 260, 최대 420
                final base = cons.maxHeight * 0.40;
                final fixedListHeight = base.clamp(260.0, 420.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 국가 토글
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
                          setState(() => _selectedCountry = sel.first);
                          _fetchDestinationsByCountry();
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 안내문
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.primary.withOpacity(.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.primary.withOpacity(.18)),
                      ),
                      child: Text(
                        '여행할 나라를 먼저 선택하고, 목적지를 검색하여 추가하세요. 여러 목적지를 선택할 수 있습니다.',
                        style: t.bodyMedium?.copyWith(
                          color: c.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 검색창 (컨텍스트 메뉴 제거)
                    TextField(
                      focusNode: _searchFocus,
                      controller: _searchController,
                      readOnly: !_typingMode,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      textInputAction: TextInputAction.search,
                      contextMenuBuilder: (ctx, state) =>
                          const SizedBox.shrink(), // ← iOS Paste/Select All 숨김
                      onTap: () {
                        if (!_typingMode) _enterTypingMode();
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
                              onPressed: () => _typingMode
                                  ? _exitTypingMode()
                                  : _enterTypingMode(),
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

                    // Chips (높이 제한↓)
                    if (_selectedDestinations.isNotEmpty) ...[
                      Text(
                        '선택된 목적지',
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 72),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedDestinations
                                .map(
                                  (d) => Chip(
                                    label: Text(d.destinationName),
                                    onDeleted: () => _removeDestination(d),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // ---- Destination List: 고정 높이 + 카드 ----
                    Builder(
                      builder: (ctx) {
                        // 평소엔 40% 고정(최소 260, 최대 420), 키보드 열리면 남은 공간 전부 사용
                        final parent = ctx.findRenderObject() as RenderBox?;
                        // 이미 바깥의 LayoutBuilder(cons.maxHeight)를 쓰고 있다면 fixed는 그대로 재사용 가능
                        final fixedListHeight =
                            (MediaQuery.of(ctx).size.height * 0.40).clamp(
                              260.0,
                              420.0,
                            );

                        final listCard = Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: Theme.of(ctx).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildListArea(ctx, state, filtered),
                        );

                        if (keyboardOpen) {
                          // 입력 중: 남은 세로 공간을 다 차지해 오버플로우 방지
                          return Expanded(child: listCard);
                        } else {
                          // 입력 아님: 보기 좋게 고정 비율/픽셀
                          return SizedBox(
                            height: fixedListHeight,
                            child: listCard,
                          );
                        }
                      },
                    ),

                    // 아래 여유: 버튼과 겹치지 않도록 최소 여백
                    SizedBox(height: keyboardOpen ? 4 : 12),
                  ],
                );
              },
            ),
          ),
        ),
      ),

      // 다음 버튼: 키보드 높이만큼 상승
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0
              ? MediaQuery.of(context).viewInsets.bottom
              : 20,
          top: 12,
        ),
        child: SafeArea(
          top: false,
          child: FilledButton(
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
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              canProceed
                  ? '다음 (${_selectedDestinations.length})'
                  : '목적지를 선택하세요',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListArea(
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
        return const Center(child: Text('목적지를 선택하세요'));
      case DestinationStatus.success:
        if (list.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
              onTap: () => _toggleDestination(d),
            );
          },
        );
    }
  }
}
