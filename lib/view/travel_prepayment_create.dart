import 'package:flutter/material.dart';

class TravelPrepaymentCreateScreen extends StatefulWidget {
  final String paymentType;
  const TravelPrepaymentCreateScreen({super.key, required this.paymentType});

  @override
  State<TravelPrepaymentCreateScreen> createState() =>
      _TravelPrepaymentCreateScreenState();
}

class _TravelPrepaymentCreateScreenState
    extends State<TravelPrepaymentCreateScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('사전사용금액 기록'),
      ),
      body: const Center(
        child: Text('사전사용금액 기록 페이지'),
      ),
    );
  }
}
