import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/record_create_request.dart';
import 'package:yoen_front/data/notifier/date_notifier.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';

class TravelRecordCreateScreen extends ConsumerStatefulWidget {
  const TravelRecordCreateScreen({super.key});

  @override
  ConsumerState<TravelRecordCreateScreen> createState() =>
      _TravelRecordCreateScreenState();
}

class _TravelRecordCreateScreenState
    extends ConsumerState<TravelRecordCreateScreen> {
  final _formKey = GlobalKey<FormState>();
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
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    if (_formKey.currentState!.validate() && travel != null) {
      final request = RecordCreateRequest(
        travelId: travel.travelId,
        title: _titleController.text,
        content: _contentController.text,
        recordTime: _selectedDateTime.toIso8601String(),
      );

      final imageFiles =
          _images.map((image) => MultipartFile.fromFileSync(image.path)).toList();

      await ref
          .read(recordNotifierProvider.notifier)
          .createRecord(request, imageFiles);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RecordState>(recordNotifierProvider, (previous, next) {
      if (next.createStatus == Status.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? '기록 저장에 실패했습니다.')),
        );
      } else if (next.createStatus == Status.success) {
        Navigator.pop(context);
      }
    });

    final recordState = ref.watch(recordNotifierProvider);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('여행 기록 작성'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '제목을 입력하세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '내용을 입력하세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(
                    '작성 시간: ${DateFormat('yyyy.MM.dd a hh:mm', 'ko_KR').format(_selectedDateTime)}',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _selectTime(context),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child:
                          Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Image.file(
                          File(_images[index].path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: recordState.createStatus == Status.loading
                      ? null
                      : _saveRecord,
                  child: recordState.createStatus == Status.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('저장'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}