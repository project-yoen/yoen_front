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

  String _getGenderString(String? gender) {
    switch (gender) {
      case 'MALE':
        return '남성';
      case 'FEMALE':
        return '여성';
      case 'OTHERS':
        return '기타';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('참여중인 유저'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: FutureBuilder<List<TravelUserDetailResponse>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('사용자 정보를 불러오는데 실패했습니다.'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('참여중인 사용자가 없습니다.'));
            }

            final users = snapshot.data!;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final genderString = _getGenderString(user.gender);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: user.imageUrl != ""
                            ? CachedNetworkImageProvider(user.imageUrl!)
                            : null,
                        child: user.imageUrl == ""
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${user.nickName} (${user.travelNickname})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    genderString,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    user.birthDay ?? '',
                                    style: const TextStyle(fontSize: 12),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
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
