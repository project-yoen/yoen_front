import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/model/payment_create_request.dart';
import 'package:yoen_front/data/model/travel_user_detail_response.dart';
import 'package:yoen_front/data/api/api_provider.dart';

class SettlementUserDialog extends ConsumerStatefulWidget {
  final int travelId;
  final List<SettlementParticipant> initialParticipants;
  final bool showPaidCheckBox;

  const SettlementUserDialog({
    super.key,
    required this.travelId,
    this.initialParticipants = const [],
    this.showPaidCheckBox = false,
  });

  @override
  ConsumerState<SettlementUserDialog> createState() =>
      _SettlementUserDialogState();
}

class _SettlementUserDialogState extends ConsumerState<SettlementUserDialog> {
  late Future<List<TravelUserDetailResponse>> _usersFuture;
  late Map<int, SettlementParticipant> _selectedUsers;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
    _selectedUsers = {
      for (final p in widget.initialParticipants) p.travelUserId: p,
    };
  }

  Future<List<TravelUserDetailResponse>> _fetchUsers() async {
    final api = ref.read(apiServiceProvider);
    final res = await api.getTravelUsers(widget.travelId);
    return res.data ?? [];
  }

  // --- helpers ---
  bool? _masterValue(List<TravelUserDetailResponse> users) {
    if (_selectedUsers.isEmpty) return false;
    if (_selectedUsers.length == users.length) return true;
    return null; // 부분 선택
  }

  void _toggleMaster(List<TravelUserDetailResponse> users, bool checked) {
    setState(() {
      if (checked) {
        // 모두 선택 (기존 isPaid 유지는 어려우니 기본 false, 이미 있던 건 유지)
        for (final u in users) {
          _selectedUsers[u.travelUserId] =
              _selectedUsers[u.travelUserId] ??
              SettlementParticipant(
                travelUserId: u.travelUserId,
                travelNickname: u.travelNickname,
                isPaid: false,
              );
        }
      } else {
        _selectedUsers.clear();
      }
    });
  }

  void _toggleUser(TravelUserDetailResponse u, bool checked) {
    setState(() {
      if (checked) {
        _selectedUsers[u.travelUserId] = SettlementParticipant(
          travelUserId: u.travelUserId,
          travelNickname: u.travelNickname,
          isPaid: _selectedUsers[u.travelUserId]?.isPaid ?? false,
        );
      } else {
        _selectedUsers.remove(u.travelUserId);
      }
    });
  }

  void _setPaid(int userId, bool paid) {
    setState(() {
      final cur = _selectedUsers[userId];
      if (cur != null) {
        _selectedUsers[userId] = SettlementParticipant(
          travelUserId: cur.travelUserId,
          travelNickname: cur.travelNickname,
          isPaid: paid,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Row(
        children: [
          Text(
            '정산 참여자 선택',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: c.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: c.primary.withOpacity(.2)),
            ),
            child: Text(
              '선택 ${_selectedUsers.length}명',
              style: t.labelMedium?.copyWith(
                color: c.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        height: 440,
        child: FutureBuilder<List<TravelUserDetailResponse>>(
          future: _usersFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('오류: ${snap.error}'));
            }
            final users = snap.data ?? [];
            if (users.isEmpty) {
              return Center(
                child: Text(
                  '참여자가 없습니다.',
                  style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                ),
              );
            }

            final master = _masterValue(users);

            return Column(
              children: [
                // 전체 선택 토글 (tristate)
                Container(
                  decoration: BoxDecoration(
                    color: c.surfaceVariant.withOpacity(.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.outlineVariant),
                  ),
                  child: CheckboxListTile(
                    value: master,
                    tristate: true,
                    dense: true,
                    title: const Text('전체 선택'),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (v) => _toggleMaster(users, v == true),
                  ),
                ),
                const SizedBox(height: 10),

                // 목록
                Expanded(
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: c.outlineVariant.withOpacity(.6),
                    ),
                    itemBuilder: (context, i) {
                      final u = users[i];
                      final selected = _selectedUsers.containsKey(
                        u.travelUserId,
                      );
                      final paid = selected
                          ? _selectedUsers[u.travelUserId]!.isPaid
                          : false;

                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => _toggleUser(u, !selected),
                        child: Container(
                          decoration: BoxDecoration(
                            color: selected ? c.primary.withOpacity(.06) : null,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            leading: Checkbox(
                              value: selected,
                              onChanged: (v) => _toggleUser(u, v ?? false),
                            ),
                            title: Text(
                              u.travelNickname,
                              style: t.bodyLarge?.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            trailing: (selected && widget.showPaidCheckBox)
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        paid
                                            ? Icons.verified
                                            : Icons.verified_outlined,
                                        size: 18,
                                        color: paid
                                            ? c.primary
                                            : c.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 6),
                                      Switch.adaptive(
                                        value: paid,
                                        onChanged: (v) =>
                                            _setPaid(u.travelUserId, v),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_selectedUsers.values.toList()),
          child: const Text('확인'),
        ),
      ],
    );
  }
}
