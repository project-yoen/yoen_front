import 'package:flutter/material.dart';

class TravelOverviewContentScreen extends StatelessWidget {
  final int travelId;

  const TravelOverviewContentScreen({super.key, required this.travelId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('전체보기 페이지: $travelId'),
    );
  }
}
