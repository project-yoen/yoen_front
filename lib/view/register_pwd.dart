import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/register_notifier.dart';
import 'package:yoen_front/view/register_name.dart';

class RegisterPwdScreen extends ConsumerStatefulWidget {
  const RegisterPwdScreen({super.key});

  @override
  ConsumerState<RegisterPwdScreen> createState() => _RegisterPwdPageState();
}

class _RegisterPwdPageState extends ConsumerState<RegisterPwdScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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
    password.addListener(() {
      setState(() {});
    });
    validPassword.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    password.dispose();
    validPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  '비밀번호 입력',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextFormField(
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
                  onFieldSubmitted: (_) {
                    final form = _formKey.currentState!;
                    if (isValidInput == null || isValidInput == false) {
                      // 아직 비밀번호 형식 검증 단계일 때
                      if (form.validate()) {
                        setState(() {
                          isValidInput = true;
                        });
                      }
                    } else {
                      // 확인 입력까지 다 했을 때
                      if (form.validate()) {
                        ref
                            .read(registerNotifierProvider.notifier)
                            .setPassword(password.text);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterNameScreen(),
                          ),
                        );
                      }
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }
                    if (!isValidPassword(value)) {
                      return '대소문자, 특수문자, 숫자, 8자리 이상';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                /// 비밀번호가 형식이 올바를시 확인 비밀번호 입력란 생성
                if (isValidInput == true)
                  TextFormField(
                    autofocus: true,
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
                    onFieldSubmitted: (_) {
                      final form = _formKey.currentState!;
                      if (isValidInput == null || isValidInput == false) {
                        // 아직 비밀번호 형식 검증 단계일 때
                        if (form.validate()) {
                          setState(() {
                            isValidInput = true;
                          });
                        }
                      } else {
                        // 확인 입력까지 다 했을 때
                        if (form.validate()) {
                          ref
                              .read(registerNotifierProvider.notifier)
                              .setPassword(validPassword.text);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterNameScreen(),
                            ),
                          );
                        }
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '비밀번호를 입력해주세요.';
                      }
                      if (value != password.text) {
                        return '비밀번호가 일치하지 않습니다.';
                      }
                      return null;
                    },
                  ),

                const Spacer(),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: (password.text.isNotEmpty &&
                            (isValidInput != true || validPassword.text.isNotEmpty))
                        ? () {
                            final form = _formKey.currentState!;
                            if (isValidInput == null || isValidInput == false) {
                              // 아직 비밀번호 형식 검증 단계일 때
                              if (form.validate()) {
                                setState(() {
                                  isValidInput = true;
                                });
                              }
                            } else {
                              // 확인 입력까지 다 했을 때
                              if (form.validate()) {
                                ref
                                    .read(registerNotifierProvider.notifier)
                                    .setPassword(validPassword.text);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterNameScreen(),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(), // 원형 버튼
                      padding: const EdgeInsets.all(20), // 버튼 크기 조절
                      backgroundColor: Colors.deepPurple, // 배경색
                      foregroundColor: Colors.white, // 아이콘 색
                      elevation: 4, // 그림자 깊이
                    ),
                    child: const Icon(Icons.arrow_forward, size: 30),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
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
}
