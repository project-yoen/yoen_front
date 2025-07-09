import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
      appBar: AppBar(title: const Text('프로필 이미지 설정')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : const AssetImage('assets/images/default_profile.png')
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
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _skipAndContinue,
                  child: const Text('건너뛰기'),
                ),
                ElevatedButton(
                  onPressed: _continueWithImage,
                  child: const Text('다음'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
