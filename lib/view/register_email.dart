import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/view/register_pwd.dart';

class RegisterEmailPage extends ConsumerStatefulWidget {
  const RegisterEmailPage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<RegisterEmailPage> createState() => _RegisterEmailPageState();
}

class _RegisterEmailPageState extends ConsumerState<RegisterEmailPage> {
  late final TextEditingController email;
  bool? isValidInput;

  @override
  void initState() {
    super.initState();
    email = TextEditingController();
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: email,
              decoration: InputDecoration(
                labelText: '이메일 주소',
                hintText: 'example@email.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => setState(() {}),
            ),
            const SizedBox(height: 10),
            if (isValidInput != null && !isValidInput!)
              const Text(
                '올바른 이메일 형식이 아닙니다.',
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: () {
                final String input = email.text;
                if (isValidEmail(input)) {
                  // 이메일 중복 검증 (이메일 api 확안)

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return RegisterPwdPage(title: "Hello");
                      },
                    ),
                  );
                  setState(() {
                    isValidInput = true;
                  });
                } else {
                  setState(() {
                    isValidInput = false;
                  });
                }
              },
              child: const Text('다음'),
            ),
          ],
        ),
      ),
    );
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }
}
