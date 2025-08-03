import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';

class RecordDetailDialog extends StatefulWidget {
  final RecordResponse record;

  const RecordDetailDialog({super.key, required this.record});

  @override
  State<RecordDetailDialog> createState() => _RecordDetailDialogState();
}

class _RecordDetailDialogState extends State<RecordDetailDialog> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recordTime = DateTime.parse(widget.record.recordTime);
    final formattedTime = DateFormat('a h:mm', 'ko_KR').format(recordTime);

    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 400,
        height: 500,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.record.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
                                              onTap: () async {
                                                Navigator.pop(
                                                  context,
                                                ); // BottomSheet 닫기

                                                // 권한 요청
                                                final granted =
                                                    await requestImageSavePermission();
                                                if (!granted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        '저장 권한이 필요합니다.',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                try {
                                                  final response = await http
                                                      .get(Uri.parse(imageUrl));
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

                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        isSuccess
                                                            ? '이미지를 저장했습니다.'
                                                            : '저장에 실패했습니다.',
                                                      ),
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '저장 중 오류 발생: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
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
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
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

Future<bool> requestImageSavePermission() async {
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      final status = await Permission.photos.request();
      return status.isGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  } else if (Platform.isIOS) {
    final status = await Permission.photosAddOnly.request();
    return status.isGranted;
  }

  return false;
}
