import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/user_response.dart';
import 'package:yoen_front/data/notifier/user_notifier.dart';

class UserEditScreen extends ConsumerStatefulWidget {
  const UserEditScreen({super.key});

  @override
  ConsumerState<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends ConsumerState<UserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  DateTime? _selectedBirthday;
  String _selectedGenderKo = '남성';

  final genderMap = {'MALE': '남성', 'FEMALE': '여성', 'OTHERS': '기타'};

  final reverseGenderMap = {'남성': 'MALE', '여성': 'FEMALE', '기타': 'OTHERS'};

  @override
  void initState() {
    super.initState();
    final user = ref.read(userNotifierProvider).value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _nicknameController = TextEditingController(text: user?.nickname ?? '');
    _selectedGenderKo = genderMap[user?.gender] ?? '남성';
    _selectedBirthday = user?.birthday != null
        ? DateTime.tryParse(user!.birthday!)
        : DateTime(2000);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthday(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userNotifier = ref.read(userNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '이름'),
                validator: (value) =>
                    value == null || value.isEmpty ? '이름을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: '닉네임'),
                validator: (value) =>
                    value == null || value.isEmpty ? '닉네임을 입력하세요' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGenderKo,
                decoration: const InputDecoration(labelText: '성별'),
                items: ['남성', '여성', '기타']
                    .map(
                      (gender) =>
                          DropdownMenuItem(value: gender, child: Text(gender)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGenderKo = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  _selectedBirthday != null
                      ? '생일: ${DateFormat('yyyy년 MM월 dd일').format(_selectedBirthday!)}'
                      : '생일을 선택하세요',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectBirthday(context),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final updatedUser = UserResponse(
                      name: _nameController.text,
                      nickname: _nicknameController.text,
                      gender: reverseGenderMap[_selectedGenderKo],
                      birthday: DateFormat(
                        'yyyy-MM-dd',
                      ).format(_selectedBirthday!),
                    );

                    // 여기에 업데이트 API 호출
                    await userNotifier.updateUserProfile(updatedUser);

                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('저장 완료')));
                  }
                },
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
