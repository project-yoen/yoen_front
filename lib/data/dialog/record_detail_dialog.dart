import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/record_response.dart';

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
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Text(
                  '여행기록 보기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
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
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4.0,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: ResponsiveShimmerImage(
                                      imageUrl:
                                          widget.record.images[index].imageUrl,
                                      aspectRatio: 4 / 3,
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
