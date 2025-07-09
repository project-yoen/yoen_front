import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/login_notifier.dart';
import 'package:yoen_front/view/register_email.dart';
import 'package:yoen_front/view/base.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool isObscuredPwd = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final FocusNode passwordFocusNode = FocusNode();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Text(
                'Yoen',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
              ),
              const Spacer(flex: 1),
              TextField(
                controller: emailController,
                focusNode: emailFocusNode,
                onSubmitted: (_) {
                  FocusScope.of(
                    context,
                  ).requestFocus(passwordFocusNode); // 다음으로 포커스 이동
                },
                decoration: InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                focusNode: passwordFocusNode,
                onSubmitted: (_) async {
                  final loginNotifier = ref.read(
                    loginNotifierProvider.notifier,
                  );
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  await loginNotifier.login(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
                  final state = ref.read(loginNotifierProvider);
                  if (state.status == LoginStatus.success) {
                    // 성공 시 페이지 이동
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const BaseScreen(),
                      ),
                      (route) => false,
                    );
                  } else if (state.status == LoginStatus.error) {
                    // 실패 시 에러 메시지 표시
                    messenger.showSnackBar(
                      SnackBar(content: Text(state.errorMessage ?? "로그인 실패")),
                    );
                  }
                },
                obscureText: isObscuredPwd,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: isObscuredPwd ? '*******' : "Example1!",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isObscuredPwd ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).primaryColorDark,
                    ),
                    onPressed: () {
                      setState(() {
                        isObscuredPwd = !isObscuredPwd;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final loginNotifier = ref.read(
                    loginNotifierProvider.notifier,
                  );
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  await loginNotifier.login(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                  );
                  final state = ref.read(loginNotifierProvider);
                  if (state.status == LoginStatus.success) {
                    // 성공 시 페이지 이동
                    navigator.pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const BaseScreen(),
                      ),
                      (route) => false,
                    );
                  } else if (state.status == LoginStatus.error) {
                    // 실패 시 에러 메시지 표시
                    messenger.showSnackBar(
                      SnackBar(content: Text(state.errorMessage ?? "로그인 실패")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18)),
              ),
              const Spacer(flex: 2),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterEmailPageScreen(),
                    ),
                  );
                },
                child: const Text(
                  '회원가입',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
