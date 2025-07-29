import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/register_notifier.dart';
import 'package:yoen_front/view/register_pwd.dart';

class RegisterEmailPageScreen extends ConsumerStatefulWidget {
  const RegisterEmailPageScreen({super.key});

  @override
  ConsumerState<RegisterEmailPageScreen> createState() =>
      _RegisterEmailPageState();
}

class _RegisterEmailPageState extends ConsumerState<RegisterEmailPageScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController email;
  bool? isValidInput;
  String? _serverErrorMessage;

  @override
  void initState() {
    super.initState();
    email = TextEditingController();
    email.addListener(() {
      // 사용자가 입력을 수정하면 서버 에러 메시지 초기화
      if (_serverErrorMessage != null) {
        setState(() {
          _serverErrorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    email.dispose();
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
                  '이메일 입력',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: email,
                  decoration: InputDecoration(
                    labelText: '이메일 주소',
                    hintText: 'example@email.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) async {
                    if (_formKey.currentState!.validate()) {
                      final isExists = await ref
                          .read(registerNotifierProvider.notifier)
                          .checkValidEmail(email.text);

                      if (!mounted) return;

                      if (!isExists) {
                        ref
                            .read(registerNotifierProvider.notifier)
                            .setEmail(email.text);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPwdScreen(),
                          ),
                        );
                      } else {
                        setState(() {
                          _serverErrorMessage = '이미 사용 중인 이메일입니다.';
                        });
                        _formKey.currentState!
                            .validate(); // 폼을 다시 그려서 validator 실행
                      }
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이메일 주소를 입력해주세요.';
                    }
                    if (!isValidEmail(email.text)) {
                      return '유효한 이메일 주소를 입력해주세요.';
                    }
                    if (_serverErrorMessage != null) {
                      return _serverErrorMessage;
                    }
                    return null;
                  },
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: (email.text.isNotEmpty)
                        ? () async {
                            if (_formKey.currentState!.validate()) {
                              final isExists = await ref
                                  .read(registerNotifierProvider.notifier)
                                  .checkValidEmail(email.text);
                              print(isExists);

                              if (!mounted) return; // context 안전 검사

                              if (!isExists) {
                                ref
                                    .read(registerNotifierProvider.notifier)
                                    .setEmail(email.text);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const RegisterPwdScreen(),
                                  ),
                                );
                              } else {
                                setState(() {
                                  _serverErrorMessage = '이미 사용 중인 이메일입니다.';
                                });
                                _formKey.currentState!.validate(); // 재검증 유도
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

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    return emailRegex.hasMatch(email);
  }
}
