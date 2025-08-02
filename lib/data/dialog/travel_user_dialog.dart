import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/api/api_provider.dart';

class TravelUserDialog extends ConsumerStatefulWidget {
  final int travelId;

  const TravelUserDialog({super.key, required this.travelId});

  @override
  ConsumerState<TravelUserDialog> createState() => _TravelUserDialogState();
}

class _TravelUserDialogState extends ConsumerState<TravelUserDialog> {
  late final Future<List<TravelUserDetailResponse>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = fetchUsers();
  }

  Future<List<TravelUserDetailResponse>> fetchUsers() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.getTravelUsers(widget.travelId);
    return response.data!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('참여중인 유저'),
      content: FutureBuilder<List<TravelUserDetailResponse>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text('사용자 정보를 불러오는데 실패했습니다.');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('참여중인 사용자가 없습니다.');
          }

          final users = snapshot.data!;
          return SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: user.imageUrl != null
                            ? CachedNetworkImageProvider(user.imageUrl!)
                            : null,
                        child: user.imageUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${user.nickName} (${user.travelNickName}) ${user.gender} ${user.birthDay}',
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
