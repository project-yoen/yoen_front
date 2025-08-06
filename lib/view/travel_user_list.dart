import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/notifier/travel_user_notifier.dart';
import 'package:yoen_front/main.dart';

class TravelUserListScreen extends ConsumerStatefulWidget {
  const TravelUserListScreen({super.key});

  @override
  ConsumerState<TravelUserListScreen> createState() =>
      _TravelUserListScreenState();
}

class _TravelUserListScreenState extends ConsumerState<TravelUserListScreen> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final travelId = ref
        .read(travelListNotifierProvider)
        .selectedTravel!
        .travelId;
    final travelUsersAsync = ref.watch(travelUserNotifierProvider(travelId));

    return Scaffold(
      appBar: AppBar(title: const Text("유저 리스트")),
      body: travelUsersAsync.when(
        data: (users) {
          return RefreshIndicator(
            onRefresh: () async {
              // API 강제 재호출
              ref
                  .read(travelUserNotifierProvider(travelId).notifier)
                  .fetchUsers();
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                _controllers.putIfAbsent(
                  user.travelUserId,
                  () => TextEditingController(text: user.travelNickName ?? ""),
                );

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "별칭:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _controllers[user.travelUserId],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: "별칭 입력",
                                ),
                                onSubmitted: (value) async {
                                  await ref
                                      .read(
                                        travelUserNotifierProvider(
                                          travelId,
                                        ).notifier,
                                      )
                                      .updateTravelNickname(
                                        user.travelUserId,
                                        value,
                                      );
                                  snackbarKey.currentState?.showSnackBar(
                                    const SnackBar(
                                      content: Text("별칭이 업데이트되었습니다."),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text("닉네임: ${user.nickName}"),
                        Text("성별: ${user.gender}"),
                        Text("생일: ${user.birthDay}"),
                        Text("User ID: ${user.travelUserId}"),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('에러 발생: $err')),
      ),
    );
  }
}
