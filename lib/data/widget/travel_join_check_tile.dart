import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';

import '../notifier/travel_join_notifier.dart';

class TravelUserJoinTile extends ConsumerWidget {
  const TravelUserJoinTile({
    super.key,
    required this.travelJoinId,
    required this.name,
    required this.gender,
    required this.imageUrl,
  });
  final int travelJoinId;
  final String name;
  final String gender;
  final String imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelJoinNotifier = ref.watch(travelJoinNotifierProvider.notifier);
    final travel = ref.read(travelListNotifierProvider).selectedTravel;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이름 + 거부 버튼 한 줄
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: CachedNetworkImageProvider(imageUrl),
                  child: const Icon(Icons.person, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => travelJoinNotifier.rejectTravelJoin(
                    travelJoinId,
                    travel!.travelId,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text("승인 거부", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(gender, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            // 읽기 / 쓰기 버튼
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => travelJoinNotifier.acceptTravelJoin(
                    travelJoinId,
                    "WRITER",
                    travel!.travelId,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text("쓰기 권한", style: TextStyle(fontSize: 12)),
                ),
                ElevatedButton.icon(
                  onPressed: () => travelJoinNotifier.acceptTravelJoin(
                    travelJoinId,
                    "READER",
                    travel!.travelId,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.book, size: 16),
                  label: const Text("읽기 권한", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
