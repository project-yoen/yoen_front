import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/api/api_provider.dart';

class SettlementUserDialog extends ConsumerStatefulWidget {
  final int travelId;

  const SettlementUserDialog({super.key, required this.travelId});

  @override
  ConsumerState<SettlementUserDialog> createState() =>
      _SettlementUserDialogState();
}

class _SettlementUserDialogState extends ConsumerState<SettlementUserDialog> {
  late final Future<List<TravelUserDetailResponse>> _usersFuture;
  final List<TravelUserDetailResponse> _selectedUsers = [];

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
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    final genderString = _getGenderString(user.gender);
                    final isSelected = _selectedUsers.contains(user);
                    return CheckboxListTile(
                      title: Text('${user.nickName} (${user.travelNickName})'),
                      subtitle: Text(genderString),
                      secondary: CircleAvatar(
                        radius: 20,
                        backgroundImage: user.imageUrl != ""
                            ? CachedNetworkImageProvider(user.imageUrl!)
                            : null,
                        child: user.imageUrl == ""
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedUsers.add(user);
                          } else {
                            _selectedUsers.remove(user);
                          }
                        });
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedUsers),
          child: const Text('선택'),
        ),
      ],
    );
  }
}
