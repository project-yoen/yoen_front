import 'package:flutter/material.dart';

import '../data/dialog/travel_code_dialog.dart';

class SimpleDialogExample extends StatelessWidget {
  const SimpleDialogExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dialog 예시')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // 👉 다이얼로그 띄우기
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => const TravelCodeDialog(),
            );
          },
          child: const Text('다이얼로그 열기'),
        ),
      ),
    );
  }
}
