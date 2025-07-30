import 'package:flutter/material.dart';

class TravelAdditionalScreen extends StatelessWidget {
  final int travelId;

  const TravelAdditionalScreen({super.key, required this.travelId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('부가 기능 페이지: $travelId')));
  }
}
