import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/user_notifier.dart';

import 'base.dart';
import 'login.dart';
import '../data/widget/progress_badge.dart'; // ProgressBadge import

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userNotifierProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: ProgressBadge(label: '시작 준비 중')),
      ),
      data: (_) => const BaseScreen(),
      error: (_, __) => const LoginScreen(),
    );
  }
}
