import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_provider.dart';
import '../data/model/register_request.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController email;
  late final TextEditingController password;
  late final TextEditingController gender;
  late final TextEditingController birthday;

  bool? isChecked = false;
  bool isSwitched = false;
  double sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    email = TextEditingController();
    password = TextEditingController();
    gender = TextEditingController();
    birthday = TextEditingController();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    gender.dispose();
    birthday.dispose();
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
        automaticallyImplyLeading:
            false, // Flutter는 자동으로 뒤로가기 버튼이 필요하면 생성하는데 이를 무시
      ),
      body: SingleChildScrollView(
        // Scrollable 한 창
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: email,
                decoration: InputDecoration(border: OutlineInputBorder()),
                onEditingComplete: () => setState(() {}),
              ),
              Text(email.text),

              TextField(
                controller: password,
                decoration: InputDecoration(border: OutlineInputBorder()),
                onEditingComplete: () => setState(() {}),
              ),
              Text(password.text),

              TextField(
                controller: gender,
                decoration: InputDecoration(border: OutlineInputBorder()),
                onEditingComplete: () => setState(() {}),
              ),
              Text(gender.text),

              TextField(
                controller: birthday,
                decoration: InputDecoration(border: OutlineInputBorder()),
                onEditingComplete: () => setState(() {}),
              ),
              Text(birthday.text),

              OutlinedButton(
                onPressed: () async {
                  final user = RegisterRequest(
                    userId: null, // 가입 시에는 없을 수 있음
                    email: email.text,
                    password: password.text,
                    gender: gender.text,
                    birthday: birthday.text,
                  );

                  try {
                    final api = ref.read(
                      apiServiceProvider,
                    ); // Retrofit 연결된 provider
                    final result = await api.register(user); // 회원가입 요청

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("가입 성공: ${result.data}")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("에러 발생: $e")));
                  }
                },
                child: Text('Submit'),
              ),
              CloseButton(),
              BackButton(),
            ],
          ),
        ),
      ),
    );
  }
}
