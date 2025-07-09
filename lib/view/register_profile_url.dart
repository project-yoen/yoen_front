import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoen_front/view/register_nickname.dart';

class RegisterProfileUrlScreen extends ConsumerStatefulWidget {
  const RegisterProfileUrlScreen({super.key});

  @override
  ConsumerState<RegisterProfileUrlScreen> createState() =>
      _RegisterProfileUrlScreenState();
}

class _RegisterProfileUrlScreenState
    extends ConsumerState<RegisterProfileUrlScreen> {
  File? _imageFile;

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                );
                if (picked != null) {
                  setState(() {
                    _imageFile = File(picked.path);
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  setState(() {
                    _imageFile = File(picked.path);
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _skipAndContinue() {
    // TODO: 프로필 없이 다음 단계로 이동
  }

  void _continueWithImage() {
    // TODO: _imageFile을 업로드하고 다음 단계로 이동
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
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              '프로필 사진',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : const AssetImage(
                                  'assets/images/default_profile.png',
                                )
                                as ImageProvider,
                      child: _imageFile == null
                          ? const Icon(
                              Icons.camera_alt,
                              size: 32,
                              color: Colors.white70,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('프로필 이미지를 선택하거나 건너뛸 수 있어요.'),
                ],
              ),
            ),

            const Spacer(),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () {
                  // 다음 로직
                  // 사진 저장후 url 받아오기
                  // ref.read(registerNotifierProvider.notifier).
                  // api로 profileurl 저장
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterNicknameScreen(),
                    ),
                  );
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
    );
  }
}
