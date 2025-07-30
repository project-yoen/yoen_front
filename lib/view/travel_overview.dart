import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yoen_front/view/travel_additional.dart';
import 'package:yoen_front/view/travel_overview_content.dart';
import 'package:yoen_front/view/travel_payment.dart';
import 'package:yoen_front/view/travel_record.dart';

class TravelOverviewScreen extends StatefulWidget {
  final int travelId;
  final String travelName;

  const TravelOverviewScreen({
    super.key,
    required this.travelId,
    required this.travelName,
  });

  @override
  State<TravelOverviewScreen> createState() => _TravelOverviewScreenState();
}

class _TravelOverviewScreenState extends State<TravelOverviewScreen> {
  int _selectedIndex = 0;

  // TODO: travelCode를 travelId를 이용해 가져오는 로직 필요
  final String _travelCode = "DUMMY-CODE"; // 임시 코드

  static const List<Widget> _widgetOptions = <Widget>[
    TravelOverviewContentScreen(),
    TravelPaymentScreen(),
    TravelRecordScreen(),
    TravelAdditionalScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.travelName),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '초대 코드 공유',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('여행 초대 코드'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('친구에게 코드를 공유하여 여행에 초대하세요!'),
                      const SizedBox(height: 20),
                      SelectableText(
                        _travelCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: _travelCode),
                        ).then((_) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('초대 코드가 복사되었습니다.')),
                          );
                        });
                      },
                      child: const Text('복사하기'),
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
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
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
    );
  }
}
