import 'package:flutter/material.dart';
import 'package:yoen_front/data/dialog/show_travel_code_dialog.dart';

class BaseScreen extends StatelessWidget {
  const BaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // 뒤로가기 버튼 제거
        title: const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '닉네임', // 하드코딩된 닉네임
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications), // 종 아이콘
            onPressed: () {
              // 알림 버튼 클릭 시 동작
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '여행 일정',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            // Expanded 대신 SizedBox로 높이 제한
            height:
                MediaQuery.of(context).size.height *
                0.50, // 화면 높이의 25%로 설정 (대략 절반)
            child: PageView.builder(
              itemCount: 3, // 임시로 3개의 여행 이미지 (플레이스홀더)
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300], // 이미지 플레이스홀더
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '여행 이미지 ${index + 1}',
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ElevatedButton(
              onPressed: () {
                // 여행 생성하기 버튼 클릭 시 동작
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('여행 생성하기', style: TextStyle(fontSize: 18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ElevatedButton(
              onPressed: () {
                // 여행 참여하기 버튼 클릭 시 동작
                showTravelCodeDialog(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('여행 참여하기', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}
