import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/travel_create_request.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';
import 'package:yoen_front/view/travel_overview.dart';
import '../data/dialog/travel_date_picker_dialog.dart';
import '../data/dialog/universal_date_picker_dialog.dart';

class TravelDetailScreen extends ConsumerStatefulWidget {
  final String nation;
  final List<int> destinationIds;

  const TravelDetailScreen({
    super.key,
    required this.nation,
    required this.destinationIds,
  });

  @override
  ConsumerState<TravelDetailScreen> createState() => _TravelDetailScreenState();
}

class _TravelDetailScreenState extends ConsumerState<TravelDetailScreen> {
  final _travelNameController = TextEditingController();
  final _travelDurationController = TextEditingController();
  final _numberOfPeopleController = TextEditingController();

  String? _currentHintTravelName;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  // 이름 추천용 단어들
  final List<String> _adjectives = [
    "우당탕탕",
    "좌충우돌",
    "재미있는",
    "신나는",
    "설레는",
    "활력 넘치는",
    "귀여운",
    "엉뚱한",
    "수상한",
    "몽글몽글",
    "눈부신",
    "따스한",
    "차가운",
    "살랑이는",
    "반짝이는",
    "꿈꾸는",
    "무계획의",
    "자유로운",
    "익숙한",
    "낯선",
    "모험적인",
    "행복한",
    "풍성한",
    "감성적인",
    "중요한",
    "기억에 남는",
    "달콤한",
    "쌉싸름한",
    "포근한",
    "은은한",
    "뜨거운",
    "서늘한",
    "웅장한",
    "아기자기한",
    "힐링되는",
    "웃음 가득한",
    "울컥하는",
    "로맨틱한",
    "익사이팅한",
    "정겨운",
    "생기 넘치는",
    "한적한",
    "요란한",
    "차분한",
    "유쾌한",
    "어딘가 이상한",
    "조용한",
    "시끌벅적한",
    "쾌활한",
    "흥미로운",
    "혼돈의",
    "잔잔한",
    "도전적인",
    "즉흥적인",
    "아름다운",
    "행운의",
    "버라이어티한",
    "리드미컬한",
    "짠내나는",
    "매운",
    "톡 쏘는",
    "사랑스러운",
    "중독성 있는",
    "청량한",
    "은밀한",
    "이색적인",
    "보통날의",
    "엉망진창",
    "성공적인",
    "특별한",
    "진지한",
    "유일한",
    "첫번째",
    "마지막",
    "지금 이 순간",
    "나른한",
    "햇살 가득한",
    "바람 부는",
    "눈 내리는",
    "비 오는",
    "맑은",
    "구름 낀",
    "오로라 같은",
    "사계절의",
    "여름의",
    "겨울의",
    "봄날의",
    "가을의",
    "야경 좋은",
    "맛있는",
    "든든한",
    "편안한",
    "깔깔거리는",
    "부러운",
    "눈물 나는",
    "짜릿한",
    "쌩쌩한",
    "느긋한",
    "알 수 없는",
  ];
  final List<String> _nouns = [
    "이쁜이들",
    "남성들",
    "여성들",
    "친구들",
    "연인들",
    "부부",
    "아이들",
    "가족",
    "단짝",
    "여행",
    "모험",
    "도전",
    "힐링",
    "퇴사자들",
    "백수들",
    "직장인들",
    "대학생들",
    "졸업여행",
    "생일파티",
    "피크닉",
    "맛집탐방",
    "야경투어",
    "캠핑",
    "로드트립",
    "자전거여행",
    "등산",
    "바다",
    "산",
    "도시",
    "섬",
    "시골",
    "휴양지",
    "리조트",
    "펜션",
    "호캉스",
    "온천",
    "테마파크",
    "페스티벌",
    "문화탐방",
    "예술기행",
    "쇼핑투어",
    "먹방",
    "야시장",
    "노을",
    "아침",
    "밤하늘",
    "반려동물",
    "동물원",
    "수족관",
    "미술관",
    "박물관",
    "명소탐방",
    "비밀장소",
    "SNS명소",
    "숨은명소",
    "열차여행",
    "기차역",
    "공항",
    "비행기",
    "여권",
    "지도",
    "숙소",
    "일출",
    "일몰",
    "여행일기",
    "브이로그",
    "사진첩",
    "영상",
    "추억",
    "기념품",
    "스냅사진",
    "데이트",
    "둘레길",
    "트레킹",
    "감성카페",
    "핫플레이스",
    "이색체험",
    "패키지여행",
    "셀프투어",
    "가이드투어",
    "즉흥여행",
    "기념일",
    "소풍",
    "첫여행",
    "마지막여행",
    "우리들의",
    "혼행",
    "단체여행",
    "커플여행",
    "절친여행",
    "슬기로운",
    "현명한",
    "여유로운",
    "행운의",
    "한정판",
    "초대박",
    "랜선여행",
    "밤도깨비",
    "아웃도어",
    "인생여행",
  ];

  @override
  void initState() {
    super.initState();
    _numberOfPeopleController.text = '1';
    _currentHintTravelName = _generateRandomTravelName();
  }

  @override
  void dispose() {
    _travelNameController.dispose();
    _travelDurationController.dispose();
    _numberOfPeopleController.dispose();
    super.dispose();
  }

  String _generateRandomTravelName() {
    final r = Random();
    return '${_adjectives[r.nextInt(_adjectives.length)]} ${_nouns[r.nextInt(_nouns.length)]}';
  }

  void _incrementPeople() {
    final cur = int.tryParse(_numberOfPeopleController.text) ?? 1;
    if (cur < 9) _numberOfPeopleController.text = '${cur + 1}';
    setState(() {});
  }

  void _decrementPeople() {
    final cur = int.tryParse(_numberOfPeopleController.text) ?? 1;
    if (cur > 1) _numberOfPeopleController.text = '${cur - 1}';
    setState(() {});
  }

  int? _diffDays() {
    if (_selectedStartDate == null || _selectedEndDate == null) return null;
    return _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;
  }

  Future<void> _pickDates() async {
    final result = await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (_) => UniversalDatePickerDialog.range(
        minDate: DateTime(2024, 1, 1),
        maxDate: DateTime(2025, 12, 31),
        initialStart: _selectedStartDate, // 선택값 있으면
        initialEnd: _selectedEndDate,
      ),
    );
    if (result == null) return;

    setState(() {
      _selectedStartDate = result['start'];
      _selectedEndDate = result['end'];
      if (_selectedStartDate != null && _selectedEndDate != null) {
        _travelDurationController.text =
            '${DateFormat('yyyy.MM.dd').format(_selectedStartDate!)} - ${DateFormat('yyyy.MM.dd').format(_selectedEndDate!)}';
      } else if (_selectedStartDate != null) {
        _travelDurationController.text = DateFormat(
          'yyyy.MM.dd',
        ).format(_selectedStartDate!);
      } else {
        _travelDurationController.clear();
      }
    });
  }

  Future<void> _handleCreateTravel() async {
    if (_selectedStartDate == null || _selectedEndDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('여행 기간을 선택해주세요.')));
      return;
    }

    final travelName = _travelNameController.text.isEmpty
        ? _currentHintTravelName!
        : _travelNameController.text;

    final request = TravelCreateRequest(
      travelName: travelName,
      numOfPeople: int.parse(_numberOfPeopleController.text),
      nation: widget.nation,
      startDate: DateFormat('yyyy-MM-dd').format(_selectedStartDate!),
      endDate: DateFormat('yyyy-MM-dd').format(_selectedEndDate!),
      destinationIds: widget.destinationIds,
    );

    final newTravel = await ref
        .read(travelListNotifierProvider.notifier)
        .createAndSelectTravel(request);

    if (!mounted) return;

    if (newTravel != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('여행이 성공적으로 생성되었습니다!')));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TravelOverviewScreen()),
        (route) => route.isFirst,
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('여행 생성에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(travelListNotifierProvider);
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final days = _diffDays();
    final canSubmit = (_selectedStartDate != null && _selectedEndDate != null);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        forceMaterialTransparency: true,
        scrolledUnderElevation: 0,
        title: const Text('여행 만들기'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: '이름 추천 새로고침',
            onPressed: () => setState(
              () => _currentHintTravelName = _generateRandomTravelName(),
            ),
            icon: const Icon(Icons.casino_outlined),
          ),
        ],
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 요약 배너
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.primary.withOpacity(.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.primary.withOpacity(.18)),
                      ),
                      child: DefaultTextStyle(
                        style: t.bodyMedium!.copyWith(color: c.onSurface),
                        child: Row(
                          children: [
                            Icon(Icons.public, color: c.primary),
                            const SizedBox(width: 8),
                            Text(
                              '나라: ',
                              style: t.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(widget.nation == 'JAPAN' ? '일본' : '한국'),
                            const SizedBox(width: 16),
                            Icon(Icons.place_outlined, color: c.primary),
                            const SizedBox(width: 6),
                            Text(
                              '목적지: ',
                              style: t.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text('${widget.destinationIds.length}곳'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 여행 이름
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: c.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '여행 이름',
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _travelNameController,
                              decoration: InputDecoration(
                                hintText: _currentHintTravelName,
                                prefixIcon: const Icon(Icons.edit_outlined),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_travelNameController.text.isNotEmpty)
                                      IconButton(
                                        tooltip: '지우기',
                                        onPressed: () {
                                          _travelNameController.clear();
                                          setState(() {});
                                        },
                                        icon: const Icon(Icons.clear),
                                      ),
                                    IconButton(
                                      tooltip: '이름 추천 새로고침',
                                      onPressed: () => setState(
                                        () => _currentHintTravelName =
                                            _generateRandomTravelName(),
                                      ),
                                      icon: const Icon(Icons.casino_outlined),
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
                            const SizedBox(height: 6),
                            Text(
                              '입력하지 않으면 추천 이름이 자동으로 사용돼요.',
                              style: t.bodySmall?.copyWith(
                                color: c.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 여행 기간
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: c.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '여행 기간',
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _travelDurationController,
                              readOnly: true,
                              onTap: _pickDates,
                              decoration: InputDecoration(
                                hintText: '기간을 선택하세요',
                                prefixIcon: const Icon(
                                  Icons.calendar_month_outlined,
                                ),
                                suffixIcon: IconButton(
                                  tooltip: '기간 선택',
                                  onPressed: _pickDates,
                                  icon: const Icon(
                                    Icons.edit_calendar_outlined,
                                  ),
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
                            if (days != null) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  Chip(
                                    label: Text('$days일 일정'),
                                    backgroundColor: c.secondaryContainer
                                        .withOpacity(.6),
                                    labelStyle: t.bodySmall?.copyWith(
                                      color: c.onSecondaryContainer,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      '${DateFormat('M월 d일').format(_selectedStartDate!)} ~ ${DateFormat('M월 d일').format(_selectedEndDate!)}',
                                    ),
                                    backgroundColor: c.surfaceVariant
                                        .withOpacity(.6),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 인원 수
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: c.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '인원 수',
                              style: t.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                IconButton.filledTonal(
                                  tooltip: '감소',
                                  onPressed: _decrementPeople,
                                  icon: const Icon(Icons.remove),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 90,
                                  child: TextField(
                                    controller: _numberOfPeopleController,
                                    readOnly: true,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: c.surfaceContainerHighest,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton.filled(
                                  tooltip: '증가',
                                  onPressed: _incrementPeople,
                                  icon: const Icon(Icons.add),
                                ),
                                const Spacer(),
                                Text(
                                  '최소 1명 · 최대 9명',
                                  style: t.bodySmall?.copyWith(
                                    color: c.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 생성 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed:
                            (listState.status == TravelListStatus.loading ||
                                !canSubmit)
                            ? null
                            : _handleCreateTravel,
                        child: (listState.status == TravelListStatus.loading)
                            ? const ProgressBadge(label: "여행 생성 중")
                            : const Text(
                                '여행 생성하기',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
