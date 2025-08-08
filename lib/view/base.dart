import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/payment_notifier.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/notifier/user_notifier.dart';
import 'package:yoen_front/data/widget/user_travel_list.dart';
import 'package:yoen_front/view/travel_list_all_screen.dart';
import 'package:yoen_front/view/user_settings.dart';
import 'package:yoen_front/view/user_travel_join.dart';

import '../data/dialog/travel_code_dialog.dart';
import '../data/notifier/common_provider.dart';
import '../data/notifier/record_notifier.dart';
import '../main.dart';
import 'login.dart';
import 'travel_destination.dart';

class BaseScreen extends ConsumerStatefulWidget {
  const BaseScreen({super.key});

  @override
  ConsumerState<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends ConsumerState<BaseScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(travelListNotifierProvider.notifier).fetchTravels();
      ref.read(recordNotifierProvider.notifier).resetAll();
      ref.read(paymentNotifierProvider.notifier).resetAll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (ref.read(dialogOpenProvider)) return;
    ref.read(travelListNotifierProvider.notifier).fetchTravels();
    ref.read(recordNotifierProvider.notifier).resetAll();
    ref.read(paymentNotifierProvider.notifier).resetAll();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: userAsync.when(
            data: (user) => InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserSettingsScreen()),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ▶ 작은 프로필 이미지(24px)
                  _TinyAvatar(
                    imageUrl: user.imageUrl, // null 가능
                    fallback: user.nickname ?? 'U', // 첫 글자 사용
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    user.nickname ?? '이름 없음',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 로딩 시 간단 스켈레톤
            loading: () => Row(
              children: [
                _TinySkeleton(size: 24),
                const SizedBox(width: 8),
                _LineSkeleton(width: 100, height: 14),
              ],
            ),
            error: (err, _) => GestureDetector(
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              ),
              child: Text(
                '오류 발생',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '알림',
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.read(travelListNotifierProvider.notifier).fetchTravels();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 섹션 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '여행 일정',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TravelListAllScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('전체 보기'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const UserTravelList(),

              const SizedBox(height: 12),
              _SectionDivider(color: theme.colorScheme.outlineVariant),

              // 버튼 부분만 발췌
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_location_alt_rounded),
                  label: const Text(
                    '여행 생성하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TravelDestinationScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.group_add_rounded),
                  label: const Text(
                    '여행 참여하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () {
                    ref.read(dialogOpenProvider.notifier).state = true;
                    showDialog(
                      context: context,
                      builder: (_) => const TravelCodeDialog(),
                    ).then((_) {
                      ref.read(dialogOpenProvider.notifier).state = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text(
                    '신청한 여행',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserTravelJoinScreen(),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ────────────── 작은 아바타/스켈레톤 ──────────────

class _TinyAvatar extends StatelessWidget {
  final String? imageUrl;
  final String fallback;
  final double size;
  const _TinyAvatar({
    required this.imageUrl,
    required this.fallback,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceVariant;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        color: bg,
        alignment: Alignment.center,
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Image.network(
                imageUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              )
            : Text(
                (fallback.isNotEmpty ? fallback[0] : 'U').toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: size * .45,
                ),
              ),
      ),
    );
  }
}

class _TinySkeleton extends StatelessWidget {
  final double size;
  const _TinySkeleton({this.size = 24});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
}

class _LineSkeleton extends StatelessWidget {
  final double width;
  final double height;
  const _LineSkeleton({required this.width, required this.height});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final Color color;
  const _SectionDivider({required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: color),
    );
  }
}
