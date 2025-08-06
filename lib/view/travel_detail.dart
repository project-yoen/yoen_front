import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/travel_create_request.dart';
import 'package:yoen_front/data/model/travel_response.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/notifier/travel_notifier.dart';
import 'package:yoen_front/view/travel_overview.dart';

import '../data/dialog/travel_date_picker_dialog.dart';

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
  final TextEditingController _travelNameController = TextEditingController();
  final TextEditingController _travelDurationController =
      TextEditingController();
  final TextEditingController _numberOfPeopleController =
      TextEditingController();

  String? _currentHintTravelName;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

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
    "자유로운",
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

  void _incrementPeople() {
    int currentCount = int.tryParse(_numberOfPeopleController.text) ?? 0;
    if (currentCount < 9) {
      setState(() {
        _numberOfPeopleController.text = (currentCount + 1).toString();
      });
    }
  }

  void _decrementPeople() {
    int currentCount = int.tryParse(_numberOfPeopleController.text) ?? 0;
    if (currentCount > 1) {
      setState(() {
        _numberOfPeopleController.text = (currentCount - 1).toString();
      });
    }
  }

  String _generateRandomTravelName() {
    final random = Random();
    final adjective = _adjectives[random.nextInt(_adjectives.length)];
    final noun = _nouns[random.nextInt(_nouns.length)];
    return '$adjective $noun';
  }

  Future<void> _createTravel() async {
    if (_selectedStartDate == null || _selectedEndDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('여행 기간을 선택해주세요.')));
      return;
    }

    final travelName = _travelNameController.text.isEmpty
        ? _currentHintTravelName!
        : _travelNameController.text;
    final numOfPeople = int.parse(_numberOfPeopleController.text);
    final nation = widget.nation;
    final startDate = DateFormat('yyyy-MM-dd').format(_selectedStartDate!);
    final endDate = DateFormat('yyyy-MM-dd').format(_selectedEndDate!);
    final destinationIds = widget.destinationIds;

    final request = TravelCreateRequest(
      travelName: travelName,
      numOfPeople: numOfPeople,
      nation: nation,
      startDate: startDate,
      endDate: endDate,
      destinationIds: destinationIds,
    );

    await ref.read(travelNotifierProvider.notifier).createTravel(request);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TravelState>(travelNotifierProvider, (previous, next) {
      if (next.status == TravelStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '여행 생성에 실패했습니다.')),
        );
      } else if (next.status == TravelStatus.success && next.travel != null) {
        final newTravel = next.travel!;
        // TravelCreateResponse를 TravelResponse로 변환
        final selectedTravel = TravelResponse(
          travelId: newTravel.travelId,
          numOfPeople: newTravel.numOfPeople,
          travelName: newTravel.travelName,
          startDate: newTravel.startDate,
          endDate: newTravel.endDate,
        );

        // 1. 생성된 여행을 travelListNotifier의 selectedTravel로 설정
        ref
            .read(travelListNotifierProvider.notifier)
            .selectTravel(selectedTravel);

        // 2. 전체 여행 목록을 다시 불러옴
        ref.read(travelListNotifierProvider.notifier).fetchTravels();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('여행이 성공적으로 생성되었습니다!')));

        // 3. 파라미터 없이 화면 이동
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const TravelOverviewScreen()),
          (route) => route.isFirst,
        );
      }
    });

    final travelState = ref.watch(travelNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        forceMaterialTransparency: true,
        scrolledUnderElevation: 0.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
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
            const Text(
              '여행 이름',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _travelNameController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: _currentHintTravelName,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '여행 기간',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _travelDurationController,
              readOnly: true,
              onTap: () async {
                final result = await showDialog<Map<String, DateTime?>>(
                  context: context,
                  builder: (BuildContext context) {
                    return TravelDatePickerDialog(
                      initialStartDate: _selectedStartDate,
                      initialEndDate: _selectedEndDate,
                    );
                  },
                );

                if (result != null) {
                  setState(() {
                    _selectedStartDate = result['start'];
                    _selectedEndDate = result['end'];
                    if (_selectedStartDate != null &&
                        _selectedEndDate != null) {
                      _travelDurationController.text =
                          '${DateFormat('yyyy.MM.dd').format(_selectedStartDate!)} - ${DateFormat('yyyy.MM.dd').format(_selectedEndDate!)}';
                    } else if (_selectedStartDate != null) {
                      _travelDurationController.text = DateFormat(
                        'yyyy.MM.dd',
                      ).format(_selectedStartDate!);
                    } else {
                      _travelDurationController.text = '';
                    }
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: '여행 기간',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '인원 수',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _decrementPeople,
                ),
                SizedBox(
                  width: 100.0,
                  child: TextFormField(
                    readOnly: true,
                    controller: _numberOfPeopleController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: '인원 수',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _incrementPeople,
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (travelState.status == TravelStatus.loading)
                    ? null
                    : () {
                        final travelListNotifier = ref.read(
                          travelListNotifierProvider.notifier,
                        );
                        int index = travelListNotifier.setCreatedIndex(
                          _selectedStartDate!,
                        );
                        print("디버깅 $index");
                        _createTravel();
                        travelListNotifier.setSelectedIndex(index);
                      },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  backgroundColor: const Color(0xFF6A4FF9),
                  foregroundColor: Colors.white,
                ),
                child: travelState.status == TravelStatus.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '여행 생성하기',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
