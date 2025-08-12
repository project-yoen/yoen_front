// lib/view/record_update_screen.dart

import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/model/record_update_request.dart';
import 'package:yoen_front/data/model/travel_record_image_response.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart';
import 'package:yoen_front/data/widget/progress_badge.dart';

import '../data/widget/responsive_shimmer_image.dart';

class TravelRecordUpdateScreen extends ConsumerStatefulWidget {
  final int travelId;
  final RecordResponse record; // ✅ 리스트에서 받은 데이터 그대로

  const TravelRecordUpdateScreen({
    super.key,
    required this.travelId,
    required this.record,
  });

  @override
  ConsumerState<TravelRecordUpdateScreen> createState() =>
      _TravelRecordUpdateScreenState();
}

class _TravelRecordUpdateScreenState
    extends ConsumerState<TravelRecordUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoMode = AutovalidateMode.disabled;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  late DateTime _selectedDateTime;

  final Set<int> _removedImageIds = {};
  final List<XFile> _newImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _titleController.text = widget.record.title;
    _contentController.text = widget.record.content ?? '';
    try {
      _selectedDateTime = DateTime.parse(widget.record.recordTime);
    } catch (_) {
      _selectedDateTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isNotEmpty) setState(() => _newImages.addAll(picked));
  }

  void _removeNewImage(int i) => setState(() => _newImages.removeAt(i));

  void _toggleRemoveServerImage(int id) {
    setState(() {
      if (_removedImageIds.contains(id)) {
        _removedImageIds.remove(id);
      } else {
        _removedImageIds.add(id);
      }
    });
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _save() async {
    final ok = _formKey.currentState!.validate();
    if (!ok) {
      setState(() => _autoMode = AutovalidateMode.onUserInteraction);
      return;
    }

    final req = RecordUpdateRequest(
      travelRecordId: widget.record.travelRecordId,
      travelId: widget.travelId,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      recordTime: _selectedDateTime.toIso8601String(),
      removeImageIds: _removedImageIds.toList(),
    );

    final files = _newImages.map((x) => File(x.path)).toList();

    await ref.read(recordNotifierProvider.notifier).updateRecord(req, files);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<RecordState>(recordNotifierProvider, (prev, next) {
      if (prev?.updateStatus != next.updateStatus) {
        if (next.updateStatus == Status.error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(next.errorMessage ?? '수정 실패')));
        } else if (next.updateStatus == Status.success) {
          Navigator.of(context).pop(true);
        }
      }
    });

    final s = ref.watch(recordNotifierProvider);
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final serverImages = widget.record.images;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('기록 수정')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoMode,
              child: ListView(
                children: [
                  _card(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '제목',
                        border: InputBorder.none,
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '제목을 입력하세요.' : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _card(
                    child: TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '내용',
                        hintText: '여행 기록을 적어보세요.',
                        border: InputBorder.none,
                      ),
                      maxLines: 6,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _selectTime,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: Text(
                          '여행 시간',
                          style: TextStyle(color: c.onSurfaceVariant),
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
                          backgroundColor: c.primary.withOpacity(.1),
                          child: Icon(Icons.access_time, color: c.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _card(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('사진', style: t.titleMedium),
                        const SizedBox(height: 12),

                        if (serverImages.isNotEmpty) ...[
                          Text('기존 사진', style: t.labelLarge),
                          const SizedBox(height: 8),
                          _ServerImagesGrid(
                            images: serverImages,
                            removedIds: _removedImageIds,
                            onToggleRemove: _toggleRemoveServerImage,
                          ),
                          const SizedBox(height: 12),
                        ],

                        Text('새로 추가', style: t.labelLarge),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: _newImages.length + 1,
                          itemBuilder: (context, idx) {
                            if (idx == 0)
                              return _AddPhotoCard(onTap: _pickImages);
                            final img = _newImages[idx - 1];
                            return _NewPhotoThumb(
                              file: File(img.path),
                              onRemove: () => _removeNewImage(idx - 1),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: s.updateStatus == Status.loading
                          ? null
                          : _save,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: s.updateStatus == Status.loading
                          ? const ProgressBadge(label: "기록 수정 중")
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

  Widget _card({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(12),
  }) {
    final c = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c.outlineVariant),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/* ---------------- 이미지 위젯들 ---------------- */

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

class _NewPhotoThumb extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _NewPhotoThumb({required this.file, required this.onRemove});

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

class _ServerImagesGrid extends StatelessWidget {
  final List<TravelRecordImageResponse> images;
  final Set<int> removedIds;
  final void Function(int id) onToggleRemove;

  const _ServerImagesGrid({
    required this.images,
    required this.removedIds,
    required this.onToggleRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, i) {
        final img = images[i];
        final id = img.travelRecordImageId;
        final url = img.imageUrl ?? '';
        final removed = removedIds.contains(id);

        return GestureDetector(
          onTap: () => onToggleRemove(id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: removed ? .35 : 1,
                child: ResponsiveShimmerImage(imageUrl: url),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: removed ? Colors.redAccent : Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    removed ? Icons.undo : Icons.delete_forever,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              if (removed)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.error.withOpacity(.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '삭제됨',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
