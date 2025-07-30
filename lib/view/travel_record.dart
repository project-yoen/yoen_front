import 'package:flutter/material.dart';

class TravelRecordScreen extends StatelessWidget {
  final int travelId;

  const TravelRecordScreen({super.key, required this.travelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('여행 기록 페이지: $travelId'),
      ),
    );
  }
}
