import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/user_response.dart';
import 'package:yoen_front/data/widget/image_cache_manager.dart';

class UserTravelCheckTile extends ConsumerWidget {
  const UserTravelCheckTile({
    super.key,
    required this.travelId,
    required this.travelName,
    required this.nation,
    required this.users,
    this.onCancel,
  });
  final int travelId;
  final String travelName;
  final String nation;
  final List<UserResponse> users;
  final void Function()? onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    travelName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onCancel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.cancel, size: 18),
                  label: const Text("신청 취소", style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(nation, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),

            /// 참여 사용자 리스트
            users.isEmpty
                ? Text(
                    '참여한 사용자가 없습니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: users
                        .map(
                          (user) => Chip(
                            avatar: CircleAvatar(
                              backgroundImage: user.imageUrl != ""
                                  ? CachedNetworkImageProvider(
                                      cacheManager: imageCacheManager,
                                      user.imageUrl!,
                                    )
                                  : null,
                              child: user.imageUrl == ""
                                  ? const Icon(Icons.person, size: 16)
                                  : null,
                            ),
                            label: Text(user.nickname ?? user.name!),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}
