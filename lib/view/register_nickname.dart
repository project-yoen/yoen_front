import 'package:flutter/material.dart';
import 'package:yoen_front/view/register_age_gender.dart';

class RegisterNicknameScreen extends StatefulWidget {
  const RegisterNicknameScreen({super.key});

  @override
  State<RegisterNicknameScreen> createState() => _RegisterNicknameScreenState();
}

class _RegisterNicknameScreenState extends State<RegisterNicknameScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
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
                child: FloatingActionButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterAgeGenderScreen(),
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.arrow_forward),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
