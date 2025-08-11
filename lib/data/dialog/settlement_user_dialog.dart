import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/api/api_provider.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';

class SettlementParticipantDto {
  final int travelUserId;
  final String travelNickName;
  bool isPaid;

  SettlementParticipantDto({
    required this.travelUserId,
    required this.travelNickName,
    this.isPaid = false,
  });
}

class SettlementUserDialog extends ConsumerStatefulWidget {
  final int travelId;
  final List<SettlementParticipantDto> initialParticipants;
  final bool showPaidCheckBox;

  const SettlementUserDialog({
    super.key,
    required this.travelId,
    this.initialParticipants = const [],
    this.showPaidCheckBox = false, // 기본값은 false
  });

  @override
  ConsumerState<SettlementUserDialog> createState() =>
      _SettlementUserDialogState();
}

class _SettlementUserDialogState extends ConsumerState<SettlementUserDialog> {
  late Future<List<TravelUserDetailResponse>> _usersFuture;
  late Map<int, SettlementParticipantDto> _selectedUsers;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
    _selectedUsers = {
      for (var p in widget.initialParticipants) p.travelUserId: p,
    };
  }

  Future<List<TravelUserDetailResponse>> _fetchUsers() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.getTravelUsers(widget.travelId);
    return response.data!;
  }

  void _onUserSelected(TravelUserDetailResponse user, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedUsers[user.travelUserId] = SettlementParticipantDto(
          travelUserId: user.travelUserId,
          travelNickName: user.travelNickName,
          // 새로 선택된 유저는 항상 isPaid가 false로 시작
          isPaid: _selectedUsers[user.travelUserId]?.isPaid ?? false,
        );
      } else {
        _selectedUsers.remove(user.travelUserId);
      }
    });
  }

  void _onPaidStatusChanged(int travelUserId, bool isPaid) {
    setState(() {
      if (_selectedUsers.containsKey(travelUserId)) {
        _selectedUsers[travelUserId]!.isPaid = isPaid;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('정산에 참여할 유저 선택'),
      content: SizedBox(
        width: 300,
        height: 400,
        child: FutureBuilder<List<TravelUserDetailResponse>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('오류: ${snapshot.error}'));
            }
            final users = snapshot.data ?? [];
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isSelected = _selectedUsers.containsKey(
                  user.travelUserId,
                );
                final isPaid = isSelected
                    ? _selectedUsers[user.travelUserId]!.isPaid
                    : false;

                return CheckboxListTile(
                  title: Text(user.travelNickName),
                  value: isSelected,
                  onChanged: (selected) =>
                      _onUserSelected(user, selected ?? false),
                  secondary: (isSelected && widget.showPaidCheckBox)
                      ? Tooltip(
                          message: '사전 정산 완료',
                          child: Checkbox(
                            value: isPaid,
                            onChanged: (paid) => _onPaidStatusChanged(
                              user.travelUserId,
                              paid ?? false,
                            ),
                            tristate: false,
                            side: const BorderSide(color: Colors.blue),
                            activeColor: Colors.blue,
                          ),
                        )
                      : null,
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
          onPressed: () =>
              Navigator.of(context).pop(_selectedUsers.values.toList()),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
