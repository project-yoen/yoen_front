import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/register_notifier.dart';
import 'package:yoen_front/view/register_age_gender.dart';

class RegisterNicknameScreen extends ConsumerStatefulWidget {
  const RegisterNicknameScreen({super.key});

  @override
  ConsumerState<RegisterNicknameScreen> createState() =>
      _RegisterNicknameScreenState();
}

class _RegisterNicknameScreenState
    extends ConsumerState<RegisterNicknameScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
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
                  '닉네임 입력',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: '닉네임',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (_) {
                    if (_formKey.currentState!.validate()) {
                      ref
                          .read(registerNotifierProvider.notifier)
                          .setNickname(_nicknameController.text);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterAgeGenderScreen(),
                        ),
                      );
                    }
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '닉네임을 입력해주세요.';
                    }
                    if (value.length > 12) {
                      return '닉네임은 12자 이내로 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () {
                      // 유효성 검사 등 처리
                      if (_formKey.currentState!.validate()) {
                        ref
                            .read(registerNotifierProvider.notifier)
                            .setNickname(_nicknameController.text);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RegisterAgeGenderScreen(),
                          ),
                        );
                      }
                    },
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
}
