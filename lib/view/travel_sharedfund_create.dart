import 'package:flutter/material.dart';

class TravelSharedfundCreateScreen extends StatefulWidget {
  final String paymentType;
  const TravelSharedfundCreateScreen({super.key, required this.paymentType});

  @override
  State<TravelSharedfundCreateScreen> createState() =>
      _TravelSharedfundCreateScreenState();
}

class _TravelSharedfundCreateScreenState
    extends State<TravelSharedfundCreateScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공금 기록'),
      ),
      body: const Center(
        child: Text('공금 기록 페이지'),
      ),
    );
  }
}
