import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/record_create_request.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';

import '../data/enums/status.dart';

class TravelRecordCreateScreen extends ConsumerStatefulWidget {
  final int travelId;
  const TravelRecordCreateScreen({super.key, required this.travelId});

  @override
  ConsumerState<TravelRecordCreateScreen> createState() =>
      _TravelRecordCreateScreenState();
}

class _TravelRecordCreateScreenState
    extends ConsumerState<TravelRecordCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  // 제출 실패 전까지는 조용, 이후 실시간 검증
  AutovalidateMode _autoMode = AutovalidateMode.disabled;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late DateTime _selectedDateTime;
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final recordDate = ref.read(dateNotifierProvider) ?? DateTime.now();
    final now = DateTime.now();
    _selectedDateTime = DateTime(
      recordDate.year,
      recordDate.month,
      recordDate.day,
      now.hour,
      now.minute,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (pickedTime != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      });
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    setState(() {
      _images.addAll(pickedFiles);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  Future<void> _saveRecord() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      setState(() => _autoMode = AutovalidateMode.onUserInteraction);
      return;
    }

    final request = RecordCreateRequest(
      travelId: widget.travelId,
      title: _titleController.text,
      content: _contentController.text,
      recordTime: _selectedDateTime.toIso8601String(),
    );

    final imageFiles = _images.map((image) => File(image.path)).toList();

    await ref
        .read(recordNotifierProvider.notifier)
        .createRecord(request, imageFiles);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RecordState>(recordNotifierProvider, (previous, next) {
      if (next.createStatus == Status.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '기록 저장에 실패했습니다.')),
        );
      } else if (next.createStatus == Status.success) {
        Navigator.pop(context, true);
      }
    });

    final recordState = ref.watch(recordNotifierProvider);
    final color = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('여행 기록 작성')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoMode, // ← 여기서 모드 제어
              child: ListView(
                children: [
                  // 제목
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '제목',
                          border: InputBorder.none,
                          hintText: '예) 부산 바다 산책',
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? '제목을 입력하세요.' : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 내용
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          labelText: '내용',
                          hintText: '여행 기록을 적어보세요.',
                          border: InputBorder.none,
                        ),
                        maxLines: 6,
                        validator: (v) => null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 작성 시간
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.outlineVariant),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        _selectTime(context);
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          '여행 시간',
                          style: TextStyle(color: color.onSurfaceVariant),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat(
                              'yyyy.MM.dd a hh:mm',
                              'ko_KR',
                            ).format(_selectedDateTime),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        trailing: CircleAvatar(
                          radius: 18,
                          backgroundColor: color.primary.withOpacity(.1),
                          child: Icon(Icons.access_time, color: color.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 사진 추가 + 그리드
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '사진',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                            itemCount: _images.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _AddPhotoCard(
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    _pickImages();
                                  },
                                );
                              }
                              final img = _images[index - 1];
                              return _PhotoThumb(
                                file: File(img.path),
                                onRemove: () => _removeImage(index - 1),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 저장 버튼
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: recordState.createStatus == Status.loading
                          ? null
                          : _saveRecord,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: recordState.createStatus == Status.loading
                          ? const ProgressBadge(label: "여행기록 처리 중")
                          : const Text('저장', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddPhotoCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceVariant.withOpacity(.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_a_photo, color: c.primary, size: 28),
              const SizedBox(height: 6),
              Text('사진 추가', style: TextStyle(color: c.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _PhotoThumb({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.cover),
          Positioned(
            top: 6,
            right: 6,
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
