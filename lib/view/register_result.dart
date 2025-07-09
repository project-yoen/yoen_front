import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/register_notifier.dart';

import 'login.dart';

class RegisterResultScreen extends ConsumerWidget {
  const RegisterResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registerState = ref.watch(registerNotifierProvider);

    final status = registerState.status;

    Widget content;

    if (status == RegisterStatus.loading) {
      content = const Center(child: CircularProgressIndicator());
    } else {
      final bool isSuccess = status == RegisterStatus.success;
      final String title = isSuccess ? '회원가입 성공!' : '회원가입 실패';
      final String message = isSuccess
          ? '이제 로그인을 통해 서비스를 이용할 수 있어요.'
          : '회원가입 중 문제가 발생했어요.\n다시 시도해주세요.';

      content = Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙 정렬
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('로그인 화면으로'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 24.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0.0,
      ),
      body: content,
    );
  }
}
