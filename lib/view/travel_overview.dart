import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yoen_front/data/dialog/travel_detail_dialog.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/overview_notifier.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart' as record;
import 'package:yoen_front/data/notifier/travel_join_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/view/travel_additional.dart';
import 'package:yoen_front/view/travel_overview_content.dart';
import 'package:yoen_front/view/travel_payment.dart';
import 'package:yoen_front/view/travel_payment_create.dart';
import 'package:yoen_front/view/travel_record.dart';
import 'package:yoen_front/view/travel_record_create.dart';
import 'package:yoen_front/view/travel_sharedfund_create.dart';

import '../data/dialog/universal_date_picker_dialog.dart';
import '../data/notifier/common_provider.dart';
import '../data/notifier/payment_notifier.dart' as payment;

class TravelOverviewScreen extends ConsumerStatefulWidget {
  const TravelOverviewScreen({super.key});

  @override
  ConsumerState<TravelOverviewScreen> createState() =>
      _TravelOverviewScreenState();
}

class _TravelOverviewScreenState extends ConsumerState<TravelOverviewScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final travel = ref.read(travelListNotifierProvider).selectedTravel;
      if (travel != null) {
        final start = DateTime.parse(travel.startDate);
        final end = DateTime.parse(travel.endDate);
        final today = DateTime.now();

        // 오늘 날짜가 여행 기간 안에 있으면 오늘, 아니면 startDate
        final defaultDate =
            (today.isAfter(start.subtract(const Duration(days: 1))) &&
                today.isBefore(end.add(const Duration(days: 1))))
            ? today
            : start;

        ref.read(dateNotifierProvider.notifier).setDate(defaultDate);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openDatePicker(BuildContext context) async {
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    if (travel == null) return;

    final start = DateTime.parse(travel.startDate);
    final end = DateTime.parse(travel.endDate);
    final current = ref.read(dateNotifierProvider);

    // initialDate 보정
    final initial =
        (current == null || current.isBefore(start) || current.isAfter(end))
        ? start
        : current;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => UniversalDatePickerDialog.single(
        minDate: start,
        maxDate: end,
        initialDate: initial,
      ),
    );

    if (picked != null) {
      final d = DateTime(picked.year, picked.month, picked.day); // 시분초 제거
      ref.read(dateNotifierProvider.notifier).setDate(d);
      _fetchData();
      HapticFeedback.selectionClick();
    }
  }

  void _onItemTapped(int index) {
    final selectedIndex = ref.read(overviewTabIndexProvider);
    if (index == selectedIndex) return;

    ref.read(overviewTabIndexProvider.notifier).state = index;

    if (index < 3) {
      _pageController.jumpToPage(index);
    }
  }

  void _onPageChanged(int index) {
    ref.read(overviewTabIndexProvider.notifier).state = index;
  }

  void _fetchData() {
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    final date = ref.read(dateNotifierProvider);
    final selectedIndex = ref.read(overviewTabIndexProvider);

    if (travel != null && date != null) {
      if (selectedIndex == 0) {
        ref
            .read(overviewNotifierProvider.notifier)
            .fetchTimeline(travel.travelId, date);
      } else if (selectedIndex == 1) {
        ref
            .read(payment.paymentNotifierProvider.notifier)
            .getPayments(travel.travelId, date, null);
      } else if (selectedIndex == 2) {
        ref
            .read(record.recordNotifierProvider.notifier)
            .getRecords(travel.travelId, date);
      }
    }
  }

  void _showAddOptions(BuildContext context, int travelId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('기록 추가'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) =>
                              TravelRecordCreateScreen(travelId: travelId),
                        ),
                      )
                      .then((value) {
                        if (value == true) {
                          _fetchData();
                        }
                      });
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: const Text('금액 추가'),
                onTap: () {
                  Navigator.pop(context);
                  _showPaymentOptions(context, travelId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPaymentOptions(BuildContext context, int travelId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          bottom: true,
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.group_add),
                title: const Text('공금기록'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => TravelSharedfundCreateScreen(
                            travelId: travelId,
                            paymentType: "SHAREDFUND",
                          ),
                        ),
                      )
                      .then((value) {
                        if (value == true) {
                          _fetchData();
                        }
                      });
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text('결제기록'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => TravelPaymentCreateScreen(
                            paymentType: "PAYMENT",
                            travelId: travelId,
                          ),
                        ),
                      )
                      .then((value) {
                        if (value == true) {
                          _fetchData();
                        }
                      });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final travel = ref.watch(travelListNotifierProvider).selectedTravel;
    final currentDate = ref.watch(dateNotifierProvider);
    final selectedIndex = ref.watch(overviewTabIndexProvider);
    final showFab = selectedIndex != 3;

    if (travel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) =>
                  TravelDetailDialog(travelId: travel.travelId),
            );
          },
          child: Text(travel.travelName),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '초대 코드 공유',
            onPressed: () async {
              await ref
                  .read(travelJoinNotifierProvider.notifier)
                  .getTravelCode(travel.travelId);

              final travelJoinState = ref.read(travelJoinNotifierProvider);
              final joinCode = travelJoinState.joinCode;

              if (joinCode == null) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('초대 코드를 불러오지 못했습니다.')),
                );
                return;
              }

              String? formattedExpireDate;
              try {
                final expireDate = DateTime.parse(joinCode.expiredAt);
                formattedExpireDate = DateFormat(
                  'yyyy년 M월 d일 HH:mm까지',
                ).format(expireDate);
              } catch (_) {
                formattedExpireDate = '만료일자 파싱 실패';
              }

              if (!mounted) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('여행 초대 코드'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '친구에게 코드를 공유하여 여행에 초대하세요!',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          GestureDetector(
                            onTap: () async {
                              await Clipboard.setData(
                                ClipboardData(text: joinCode.code),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('초대 코드가 복사되었습니다.'),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              joinCode.code,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: joinCode.code),
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('초대 코드가 복사되었습니다.'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (formattedExpireDate != null)
                        Text(
                          '유효기간: $formattedExpireDate',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        final shareText =
                            '''
여행 초대 코드: ${joinCode.code}
유효기간: $formattedExpireDate

아래 앱에서 코드를 입력하여 여행에 참여하세요!
https://your-app-link.com
''';
                        await Share.share(
                          shareText.trim(),
                          subject: '여행 초대 코드 공유',
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('공유하기'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('닫기'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: '알림',
            onPressed: () {
              // TODO: 알림 화면으로 이동
            },
          ),
        ],
      ),

      body: Column(
        children: [
          if (currentDate != null && selectedIndex != 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        visible: currentDate.isAfter(
                          DateTime.parse(travel.startDate),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          onPressed: () {
                            ref
                                .read(dateNotifierProvider.notifier)
                                .previousDay(DateTime.parse(travel.startDate));
                            _fetchData();
                          },
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _openDatePicker(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 6,
                          ),
                          child: Text(
                            DateFormat('yyyy.MM.dd').format(currentDate),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        visible: currentDate.isBefore(
                          DateTime.parse(travel.endDate),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          onPressed: () {
                            ref
                                .read(dateNotifierProvider.notifier)
                                .nextDay(DateTime.parse(travel.endDate));
                            _fetchData();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          // 노치/하단바 간섭 완화
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Stack(
                children: [
                  Offstage(
                    offstage: selectedIndex == 3,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: const [
                        TravelOverviewContentScreen(),
                        TravelPaymentScreen(),
                        TravelRecordScreen(),
                      ],
                    ),
                  ),
                  Offstage(
                    offstage: selectedIndex != 3,
                    child: const TravelAdditionalScreen(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ✅ 중앙 도킹 확장형 FAB: 탭과 분리된 '추가' CTA
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              heroTag: 'travelOverviewFab',
              onPressed: () {
                HapticFeedback.lightImpact();
                if (selectedIndex == 0) {
                  _showAddOptions(context, travel.travelId); // 기록/금액 선택
                } else if (selectedIndex == 1) {
                  _showPaymentOptions(context, travel.travelId); // 공금/결제 선택
                } else if (selectedIndex == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TravelRecordCreateScreen(travelId: travel.travelId),
                    ),
                  ).then((value) {
                    if (value == true) _fetchData();
                  });
                }
              },
              tooltip: '추가',
              icon: const Icon(Icons.add),
              label: const Text(
                '추가',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 8,
              shape: const StadiumBorder(),
              extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
            )
          : null,

      // ✅ BottomNavigationBar → BottomAppBar (FAB 모양과 노치 자동 정합)
      bottomNavigationBar: BottomAppBar(
        shape: const AutomaticNotchedShape(
          RoundedRectangleBorder(),
          StadiumBorder(),
        ),
        notchMargin: 10,
        elevation: 10,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              // 왼쪽 2개 탭: 남는 공간을 자동 분배
              Expanded(
                child: _NavItem(
                  icon: Icons.home,
                  label: '전체보기',
                  selected: selectedIndex == 0,
                  onTap: () => _onItemTapped(0),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.payment,
                  label: '금액기록',
                  selected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1),
                ),
              ),

              // 중앙 FAB 공간 (확장형 FAB 고려해 80px 전후 권장)
              const SizedBox(width: 84),

              // 오른쪽 2개 탭
              Expanded(
                child: _NavItem(
                  icon: Icons.book,
                  label: '여행기록',
                  selected: selectedIndex == 2,
                  onTap: () => _onItemTapped(2),
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.more_horiz,
                  label: '부가기능',
                  selected: selectedIndex == 3,
                  onTap: () => _onItemTapped(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 탭 버튼 위젯 (BottomAppBar용)
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: double.infinity, // ← 높이만 채우고, 너비는 Expanded가 관리
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
