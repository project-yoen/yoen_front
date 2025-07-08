import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RegisterPwdPage extends ConsumerStatefulWidget {
  const RegisterPwdPage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<RegisterPwdPage> createState() => _RegisterPwdPageState();
}

class _RegisterPwdPageState extends ConsumerState<RegisterPwdPage> {
  late final TextEditingController password;
  late final TextEditingController validPassword;

  /// isValidInput: 비밀번호 형식이 옳은지
  /// isPasswordMatched: 비밀번호가 일치하는지
  /// isObscuredPwd: 비밀번호 가시성
  /// isObscuredValidPwd: 비밀번호 확인 가시성
  ///
  bool? isValidInput;
  bool? isPasswordMatched;
  bool isObscuredPwd = true;
  bool isObscuredValidPwd = true;

  @override
  void initState() {
    super.initState();
    password = TextEditingController();
    validPassword = TextEditingController();
  }

  @override
  void dispose() {
    password.dispose();
    validPassword.dispose();
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
              controller: password,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: isObscuredPwd ? '*******' : "Example1!",
                border: OutlineInputBorder(),
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
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              obscureText: isObscuredPwd,
            ),
            const SizedBox(height: 10),

            /// 비밀번호 형식이 옳바르지 않을시
            if (isValidInput != null && !isValidInput!)
              const Text(
                '대소문자, 문자 및 숫자를 포함한 형식이어야 합니다.',
                style: TextStyle(color: Colors.red),
              ),

            /// 비밀번호가 형식이 올바를시 확인 비밀번호 입력란 생성
            if (isValidInput != null && isValidInput!)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  TextField(
                    controller: validPassword,
                    decoration: InputDecoration(
                      labelText: 'Validate Password',
                      hintText: isObscuredValidPwd ? '*******' : "Example!",
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isObscuredValidPwd
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Theme.of(context).primaryColorDark,
                        ),
                        onPressed: () {
                          setState(() {
                            isObscuredValidPwd = !isObscuredValidPwd;
                          });
                        },
                      ),
                    ),
                    obscureText: isObscuredValidPwd,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 10),
                ],
              ),

            /// 비밀번호가 일치하지 않을시
            if (isPasswordMatched != null && !isPasswordMatched!)
              const Text(
                '비밀번호가 일치하지 않습니다.',
                style: TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                /// 비밀번호 형식이 올바르고 비밀번호가 일치할시
                if (isValidInput == true && isMatchedPassword()) {
                  // 다음으로 이동
                }

                /// 비밀번호 형식 검증 (즉 Elevated Button이 두개의 기능을 함)
                /// 1. 비밀번호 형식 검증, 2. 비밀번호 일치 검증
                final String input = password.text;
                if (isValidPassword(input)) {
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

  bool isValidPassword(String password) {
    // 최소 8자, 영문 대소문자, 숫자, 특수문자 포함 여부 확인
    final passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  bool isMatchedPassword() {
    if (password.text == validPassword.text) {
      setState(() {
        isPasswordMatched = true;
      });
      return true;
    } else {
      setState(() {
        isPasswordMatched = false;
      });
      return false;
    }
  }
}
