import 'package:flutter/material.dart';

class TravelPaymentScreen extends StatelessWidget {
  final int travelId;

  const TravelPaymentScreen({super.key, required this.travelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('금액 기록 페이지: $travelId'),
      ),
    );
  }
}
