import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';

import '../../main.dart';
import '../../view/image_preview.dart';

class RecordDetailDialog extends ConsumerStatefulWidget {
  final RecordResponse record;

  const RecordDetailDialog({super.key, required this.record});

  @override
  ConsumerState<RecordDetailDialog> createState() => _RecordDetailDialogState();
}

class _RecordDetailDialogState extends ConsumerState<RecordDetailDialog> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmDialog(RecordResponse record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('기록 삭제'),
          content: Text('\'${record.title}\'을(를) 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                ref
                    .read(recordNotifierProvider.notifier)
                    .deleteRecord(record.travelRecordId);
                Navigator.of(context).pop(); // Close confirmation dialog
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recordTime = DateTime.parse(widget.record.recordTime);
    final formattedTime = DateFormat('a h:mm', 'ko_KR').format(recordTime);

    ref.listen<RecordState>(recordNotifierProvider, (previous, next) {
      if (next.deleteStatus == Status.success) {
        Navigator.of(context).pop(); // Close detail dialog
      } else if (next.deleteStatus == Status.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '삭제에 실패했습니다.')),
        );
      }
    });

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: Text(
                              widget.record.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () =>
                              _showDeleteConfirmDialog(widget.record),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.record.travelNickName,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (widget.record.images.isNotEmpty)
                      Column(
                        children: [
                          SizedBox(
                            height: 270,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: widget.record.images.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                final imageUrl =
                                    widget.record.images[index].imageUrl;

                                return GestureDetector(
                                  onTap: () {
                                    context.pushTransparentRoute(
                                      ImagePreviewPage(
                                        imageUrls: widget.record.images
                                            .map((image) => image.imageUrl)
                                            .toList(),
                                        initialIndex: index,
                                      ),
                                    );
                                  },
                                  onLongPress: () {
                                    showModalBottomSheet(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                      ),
                                      builder: (_) => SafeArea(
                                        child: Wrap(
                                          children: [
                                            ListTile(
                                              leading: const Icon(
                                                Icons.download,
                                              ),
                                              title: const Text('사진 저장하기'),
                                              onTap: () {
                                                Navigator.pop(
                                                  context,
                                                ); // BottomSheet 닫기

                                                Future.delayed(Duration.zero, () async {
                                                  final granted =
                                                      await requestImageSavePermission(
                                                        context,
                                                      );
                                                  if (!granted) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            '저장 권한이 필요합니다.',
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                    return;
                                                  }

                                                  try {
                                                    final response = await http
                                                        .get(
                                                          Uri.parse(imageUrl),
                                                        );
                                                    final Uint8List bytes =
                                                        response.bodyBytes;

                                                    final result =
                                                        await ImageGallerySaverPlus.saveImage(
                                                          bytes,
                                                          quality: 100,
                                                          name:
                                                              "travel_image_${DateTime.now().millisecondsSinceEpoch}",
                                                        );

                                                    final isSuccess =
                                                        result['isSuccess'] ??
                                                        result['success'] ??
                                                        false;

                                                    snackbarKey.currentState
                                                        ?.showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              isSuccess
                                                                  ? '이미지를 저장했습니다.'
                                                                  : '저장에 실패했습니다.',
                                                            ),
                                                          ),
                                                        );
                                                  } catch (e) {
                                                    snackbarKey.currentState
                                                        ?.showSnackBar(
                                                          SnackBar(
                                                            content: Text(
                                                              '저장 중 오류 발생: $e',
                                                            ),
                                                          ),
                                                        );
                                                  }
                                                });
                                              },
                                            ),
                                            ListTile(
                                              leading: const Icon(Icons.share),
                                              title: const Text('공유하기'),
                                              onTap: () async {
                                                Navigator.pop(
                                                  context,
                                                ); // BottomSheet 닫기

                                                try {
                                                  final uri = Uri.parse(
                                                    imageUrl,
                                                  );
                                                  final response = await http
                                                      .get(uri);
                                                  final bytes =
                                                      response.bodyBytes;

                                                  // temp 디렉토리에 저장
                                                  final tempDir =
                                                      await getTemporaryDirectory();
                                                  final file = await File(
                                                    '${tempDir.path}/shared_image.jpg',
                                                  ).create();
                                                  await file.writeAsBytes(
                                                    bytes,
                                                  );

                                                  await Share.shareXFiles([
                                                    XFile(file.path),
                                                  ]);
                                                } catch (e) {
                                                  snackbarKey.currentState
                                                      ?.showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            '공유 중 오류 발생: $e',
                                                          ),
                                                        ),
                                                      );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: ResponsiveShimmerImage(
                                        imageUrl: imageUrl,
                                        aspectRatio: 4 / 3,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.record.images.length,
                              (index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  height: 8.0,
                                  width: _currentIndex == index ? 12.0 : 8.0,
                                  decoration: BoxDecoration(
                                    color: _currentIndex == index
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Text(
                      widget.record.content,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 18.0, right: 10.0),
                child: Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 15, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> requestImageSavePermission(BuildContext context) async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      final status = await Permission.photos.request();
      if (status.isGranted) return true;
      return await _handleDenied(context, Permission.photos);
    } else {
      final status = await Permission.storage.request();
      if (status.isGranted) return true;
      return await _handleDenied(context, Permission.storage);
    }
  } else if (Platform.isIOS) {
    final status = await Permission.photos.request();
    if (status.isGranted || status.isLimited) return true;
    return await _handleDenied(context, Permission.photos);
  }

  return false;
}

Future<bool> _handleDenied(BuildContext context, Permission permission) async {
  final currentStatus = await permission.status;

  if (currentStatus.isDenied ||
      currentStatus.isPermanentlyDenied ||
      currentStatus.isRestricted) {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('권한이 필요합니다'),
        content: const Text('사진을 저장하려면 권한이 필요합니다. 설정으로 이동하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('설정 열기'),
          ),
        ],
      ),
    );

    if (shouldOpenSettings == true) {
      await openAppSettings();
    }
    return false;
  }

  return false;
}
