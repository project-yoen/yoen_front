import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/notifier/travel_user_notifier.dart';
import 'package:yoen_front/main.dart';

class TravelUserListScreen extends ConsumerWidget {
  const TravelUserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travelId = ref
        .read(travelListNotifierProvider)
        .selectedTravel!
        .travelId;
    final usersAsync = ref.watch(travelUserNotifierProvider(travelId));

    return Scaffold(
      appBar: AppBar(title: const Text('여행 멤버')),
      body: usersAsync.when(
        data: (users) => RefreshIndicator(
          onRefresh: () async => ref
              .read(travelUserNotifierProvider(travelId).notifier)
              .fetchUsers(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final u = users[i];
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      // 헤더: 아바타 + 닉네임 + 인라인 메타
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: _ProfileAvatar(
                          imageUrl: (u.imageUrl ?? ''),
                          fallbackText: (u.nickName?.isNotEmpty == true
                              ? u.nickName![0]
                              : 'U'),
                        ),
                        title: Text(
                          (u.nickName?.isNotEmpty == true)
                              ? u.nickName!
                              : '닉네임 없음',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: _MetaInline(
                          gender: u.gender,
                          birthDay: u.birthDay,
                        ),
                      ),

                      const Divider(height: 1),

                      // 별칭 표시 줄: 탭하면 수정 다이얼로그
                      InkWell(
                        onTap: () => _editAliasDialog(
                          context,
                          ref,
                          travelId,
                          u.travelUserId,
                          u.travelNickName ?? '',
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                          child: Row(
                            children: [
                              Text(
                                '별칭',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  (u.travelNickName?.isNotEmpty == true)
                                      ? u.travelNickName!
                                      : '설정되지 않음',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: '별칭 수정',
                                icon: const Icon(Icons.edit_rounded),
                                onPressed: () => _editAliasDialog(
                                  context,
                                  ref,
                                  travelId,
                                  u.travelUserId,
                                  u.travelNickName ?? '',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('에러: $e')),
      ),
    );
  }

  Future<void> _editAliasDialog(
    BuildContext context,
    WidgetRef ref,
    int travelId,
    int travelUserId,
    String currentAlias,
  ) async {
    final controller = TextEditingController(text: currentAlias);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('별칭 수정'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: '표시할 별칭을 입력하세요',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (result == null) return; // 취소
    await ref
        .read(travelUserNotifierProvider(travelId).notifier)
        .updateTravelNickname(travelUserId, result);
    snackbarKey.currentState?.showSnackBar(
      const SnackBar(content: Text('별칭이 업데이트되었습니다.')),
    );
    FocusScope.of(context).unfocus();
  }
}

class _MetaInline extends StatelessWidget {
  final String? gender;
  final String? birthDay;
  const _MetaInline({this.gender, this.birthDay});

  String _ageFrom(String birth) {
    try {
      final b = DateTime.parse(birth);
      final now = DateTime.now();
      var age = now.year - b.year;
      if (now.month < b.month || (now.month == b.month && now.day < b.day))
        age--;
      return '$age';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final onVar = Theme.of(context).colorScheme.onSurfaceVariant;
    final small = Theme.of(context).textTheme.bodySmall?.copyWith(color: onVar);
    final items = <String>[
      if ((gender ?? '').isNotEmpty) '성별: $gender',
      if ((birthDay ?? '').isNotEmpty) '생일: $birthDay',
      if ((birthDay ?? '').isNotEmpty) '나이: ${_ageFrom(birthDay!)}',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Wrap(
        spacing: 16,
        runSpacing: 2,
        children: items.map((t) => Text(t, style: small)).toList(),
      ),
    );
  }
}

/// 프로필 아바타(캐시 + 플레이스홀더 + 에러 핸들)
class _ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final String fallbackText;
  const _ProfileAvatar({required this.imageUrl, required this.fallbackText});

  @override
  Widget build(BuildContext context) {
    final hasUrl = imageUrl.isNotEmpty;
    final bg = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: bg,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => _InitialsBox(fallbackText, bg),
              )
            : _InitialsBox(fallbackText, bg),
      ),
    );
  }
}

class _InitialsBox extends StatelessWidget {
  final String text;
  final Color bg;
  const _InitialsBox(this.text, this.bg);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
