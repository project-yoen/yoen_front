import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yoen_front/data/notifier/login_notifier.dart';
import 'package:yoen_front/view/user_edit.dart';

import '../data/notifier/user_notifier.dart';

class UserSettingsScreen extends ConsumerStatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  ConsumerState<UserSettingsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends ConsumerState<UserSettingsScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<void> _showImageSourceSelector(WidgetRef ref) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('사진 찍기'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndCropImage(ImageSource.camera, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndCropImage(ImageSource.gallery, ref);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndCropImage(ImageSource source, WidgetRef ref) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '사진 자르기',
          toolbarColor: Colors.deepPurple,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: '사진 자르기', aspectRatioLockEnabled: true),
      ],
    );

    if (cropped != null) {
      setState(() {
        _selectedImage = File(cropped.path);
      });

      // TODO: 서버 업로드 로직 추가 (8/2일에 마저 하기)
      ref.read(userNotifierProvider.notifier).updateImage(_selectedImage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userNotifierProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final avatarRadius = screenWidth * 0.15;

    return Scaffold(
      appBar: AppBar(
        title: const Text("사용자 설정"),
        forceMaterialTransparency: true,
        scrolledUnderElevation: 0,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('오류 발생: $error')),
        data: (user) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: () => _showImageSourceSelector(ref),
                            child: Container(
                              width: avatarRadius * 2,
                              height: avatarRadius * 2,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _selectedImage != null
                                  ? Image.file(
                                      _selectedImage!,
                                      fit: BoxFit.cover,
                                    )
                                  : user.imageUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: user.imageUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : const Center(
                                      child: Icon(Icons.person, size: 32),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _showImageSourceSelector(ref),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                padding: const EdgeInsets.all(6),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        user!.name!,
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserEditScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('개인정보 변경', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => showLogoutDialog(
                    context,
                    () => ref
                        .read(loginNotifierProvider.notifier)
                        .logout(context),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('로그아웃', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void showLogoutDialog(BuildContext context, VoidCallback onLogout) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onLogout();
            },
            child: const Text('로그아웃'),
          ),
        ],
      );
    },
  );
}
