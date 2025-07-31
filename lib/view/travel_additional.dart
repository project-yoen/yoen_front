import 'package:flutter/material.dart';
import 'package:yoen_front/view/travel_user_join.dart';

class TravelAdditionalScreen extends StatelessWidget {
  const TravelAdditionalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  //여행 생성하기 버튼 누를 시 동작
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelUserJoinScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('신청한 여행', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
