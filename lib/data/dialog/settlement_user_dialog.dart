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
    this.initialSelectedUserIds = const [],
  });

  @override
  ConsumerState<SettlementUserDialog> createState() =>
      _SettlementUserDialogState();
}

class _SettlementUserDialogState extends ConsumerState<SettlementUserDialog> {
  late Future<List<TravelUserDetailResponse>> _usersFuture;

  /// 선택 상태는 id 기준으로 관리(동등성 문제 방지)
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
    _selectedIds = widget.initialSelectedUserIds.toSet();
  }

  Future<List<TravelUserDetailResponse>> _fetchUsers() async {
    final api = ref.read(apiServiceProvider);
    final response = await api.getTravelUsers(widget.travelId);
    return response.data ?? <TravelUserDetailResponse>[];
  }

  String _genderLabel(String? gender) {
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
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('정산에 참여할 유저 선택'),
      content: SizedBox(
        width: 340,
        height: 420,
        child: FutureBuilder<List<TravelUserDetailResponse>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('사용자 정보를 불러오는데 실패했습니다.'));
            }
            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return const Center(child: Text('참여중인 사용자가 없습니다.'));
            }

            return StatefulBuilder(
              builder: (context, setStateSB) {
                final allSelected =
                    users.isNotEmpty && _selectedIds.length == users.length;
                return Column(
                  children: [
                    // 상단 액션바: 전체 선택/해제
                    Row(
                      children: [
                        Text(
                          '선택됨 ${_selectedIds.length}/${users.length}',
                          style: t.bodyMedium?.copyWith(
                            color: c.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setStateSB(() {
                              if (allSelected) {
                                _selectedIds.clear();
                              } else {
                                _selectedIds = users
                                    .map((u) => u.travelUserId)
                                    .toSet();
                              }
                            });
                          },
                          icon: Icon(
                            allSelected
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            size: 18,
                          ),
                          label: Text(allSelected ? '전체해제' : '전체선택'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: ListView.separated(
                        itemCount: users.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: c.outlineVariant),
                        itemBuilder: (context, index) {
                          final u = users[index];
                          final isSelected = _selectedIds.contains(
                            u.travelUserId,
                          );
                          return ListTile(
                            onTap: () {
                              setStateSB(() {
                                if (isSelected) {
                                  _selectedIds.remove(u.travelUserId);
                                } else {
                                  _selectedIds.add(u.travelUserId);
                                }
                              });
                            },
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage:
                                  (u.imageUrl != null && u.imageUrl!.isNotEmpty)
                                  ? CachedNetworkImageProvider(u.imageUrl!)
                                  : null,
                              child: (u.imageUrl == null || u.imageUrl!.isEmpty)
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(
                              '${u.nickName} (${u.travelNickName})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(_genderLabel(u.gender)),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setStateSB(() {
                                  if (val == true) {
                                    _selectedIds.add(u.travelUserId);
                                  } else {
                                    _selectedIds.remove(u.travelUserId);
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
          onPressed: () async {
            // id 기반 선택을 실제 객체 리스트로 변환하여 반환
            final users = await _usersFuture;
            final selectedUsers = users
                .where((u) => _selectedIds.contains(u.travelUserId))
                .toList();
            Navigator.of(context).pop(selectedUsers);
          },
          child: const Text('선택'),
        ),
      ],
    );
  }
}
