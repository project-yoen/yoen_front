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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => travelJoinNotifier.acceptTravelJoin(
                    travelJoinId,
                    "WRITER",
                    travel!.travelId,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text("쓰기 권한", style: TextStyle(fontSize: 13)),
                ),
                ElevatedButton.icon(
                  onPressed: () => travelJoinNotifier.acceptTravelJoin(
                    travelJoinId,
                    "READER",
                    travel!.travelId,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text("읽기 권한", style: TextStyle(fontSize: 13)),
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
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text("거부", style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(gender, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
