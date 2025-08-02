import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/register_notifier.dart';
import 'package:yoen_front/view/register_age_gender.dart';

class RegisterNameScreen extends ConsumerStatefulWidget {
  const RegisterNameScreen({super.key});

  @override
  ConsumerState<RegisterNameScreen> createState() => _RegisterNameScreenState();
}

class _RegisterNameScreenState extends ConsumerState<RegisterNameScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {});
    });
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
                  '이름 입력',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (_) {
                    if (_formKey.currentState!.validate()) {
                      ref
                          .read(registerNotifierProvider.notifier)
                          .setName(_nameController.text);
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
                      return '이름을 입력해주세요.';
                    }
                    return null;
                  },
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: (_nameController.text.isNotEmpty)
                        ? () {
                            // 유효성 검사 등 처리
                            if (_formKey.currentState!.validate()) {
                              ref
                                  .read(registerNotifierProvider.notifier)
                                  .setName(_nameController.text);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegisterAgeGenderScreen(),
                                ),
                              );
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
}
