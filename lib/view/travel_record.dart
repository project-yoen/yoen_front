import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/notifier/record_notifier.dart';

class TravelRecordScreen extends ConsumerStatefulWidget {
  final int travelId;
  final DateTime date;
  final DateTime startDate;
  final DateTime endDate;

  const TravelRecordScreen({
    super.key,
    required this.travelId,
    required this.date,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<TravelRecordScreen> createState() => _TravelRecordScreenState();
}

class _TravelRecordScreenState extends ConsumerState<TravelRecordScreen> {
  @override
  void initState() {
    super.initState();
    // initState에서 데이터를 비동기적으로 로드합니다.
    Future.microtask(() => ref
        .read(recordNotifierProvider.notifier)
        .getRecords(widget.travelId, widget.date));
  }

  @override
  void didUpdateWidget(covariant TravelRecordScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.date != oldWidget.date) {
      Future.microtask(() => ref
          .read(recordNotifierProvider.notifier)
          .getRecords(widget.travelId, widget.date));
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordState = ref.watch(recordNotifierProvider);

    return Scaffold(
      // AppBar는 travel_overview.dart에 있으므로 여기서는 제거합니다.
      body: _buildBody(recordState),
    );
  }

  Widget _buildBody(RecordState state) {
    switch (state.getStatus) {
      case Status.loading:
        return const Center(child: CircularProgressIndicator());
      case Status.error:
        return Center(
          child: Text('오류가 발생했습니다: ${state.errorMessage}'),
        );
      case Status.success:
        if (state.records.isEmpty) {
          return const Center(
            child: Text('이 날짜에 작성된 기록이 없습니다.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: state.records.length,
          itemBuilder: (context, index) {
            final record = state.records[index];
            return _buildRecordCard(record);
          },
        );
      default:
        return const Center(child: Text('기록을 불러오는 중...'));
    }
  }

  Widget _buildRecordCard(RecordResponse record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              record.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (record.images.isNotEmpty) ...[
              const SizedBox(height: 16.0),
              _buildImageGallery(record.images),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                images[index],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error, color: Colors.red);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}