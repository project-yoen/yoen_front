import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/overview_notifier.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart';
import 'package:yoen_front/data/notifier/travel_join_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/view/travel_additional.dart';
import 'package:yoen_front/view/travel_overview_content.dart';
import 'package:yoen_front/view/travel_payment.dart';
import 'package:yoen_front/view/travel_payment_create.dart';
import 'package:yoen_front/view/travel_prepayment_create.dart';
import 'package:yoen_front/view/travel_record.dart';
import 'package:yoen_front/view/travel_record_create.dart';
import 'package:yoen_front/view/travel_detail_page.dart';
import 'package:yoen_front/view/travel_sharedfund_create.dart';

import '../data/notifier/payment_notifier.dart';

class TravelOverviewScreen extends ConsumerStatefulWidget {
  const TravelOverviewScreen({super.key});

  @override
  ConsumerState<TravelOverviewScreen> createState() =>
      _TravelOverviewScreenState();
}

class _TravelOverviewScreenState extends ConsumerState<TravelOverviewScreen> {
  late PageController _pageController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final travel = ref.read(travelListNotifierProvider).selectedTravel;
      if (travel != null) {
        ref
            .read(dateNotifierProvider.notifier)
            .setDate(DateTime.parse(travel.startDate));
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index < 3) {
      // PageView에 포함된 탭으로 이동
      _pageController.jumpToPage(index);
    }
    // index가 3일 경우, setState만으로 Offstage가 제어하여 화면이 전환됨
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _fetchData() {
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    final date = ref.read(dateNotifierProvider);
    if (travel != null && date != null) {
      if (_selectedIndex == 0) {
        ref
            .read(overviewNotifierProvider.notifier)
            .fetchTimeline(travel.travelId, date);
      } else if (_selectedIndex == 1) {
        ref
            .read(paymentNotifierProvider.notifier)
            .getPayments(travel.travelId, date);
      } else if (_selectedIndex == 2) {
        ref
            .read(recordNotifierProvider.notifier)
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TravelDetailPage(travelId: travel.travelId),
              ),
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
          if (currentDate != null && _selectedIndex != 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
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
                      onPressed: () => ref
                          .read(dateNotifierProvider.notifier)
                          .previousDay(DateTime.parse(travel.startDate)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      DateFormat('yyyy.MM.dd').format(currentDate),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                      onPressed: () => ref
                          .read(dateNotifierProvider.notifier)
                          .nextDay(DateTime.parse(travel.endDate)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                Offstage(
                  offstage: _selectedIndex == 3,
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
                  offstage: _selectedIndex != 3,
                  child: const TravelAdditionalScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '전체보기'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: '금액기록'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '여행기록'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: '부가기능'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButton: () {
        if (_selectedIndex == 3) return null; // 부가기능 탭에서는 숨김

        return FloatingActionButton(
          onPressed: () {
            if (_selectedIndex == 0) {
              _showAddOptions(context, travel.travelId);
            } else if (_selectedIndex == 1) {
              _showPaymentOptions(context, travel.travelId);
            } else if (_selectedIndex == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      TravelRecordCreateScreen(travelId: travel.travelId),
                ),
              ).then((value) {
                if (value == true) {
                  _fetchData();
                }
              });
            }
          },
          child: const Icon(Icons.add),
        );
      }(),
    );
  }
}
