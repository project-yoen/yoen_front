import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yoen_front/data/notifier/travel_list_notifier.dart';
import 'package:yoen_front/data/notifier/travel_notifier.dart';
import 'package:yoen_front/main.dart';
import 'package:yoen_front/view/settlement.dart';
import 'package:yoen_front/view/travel_detail_page.dart';
import 'package:yoen_front/view/travel_prepayment_create.dart';

import 'base.dart';

class TravelAdditionalScreen extends ConsumerWidget {
  const TravelAdditionalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final travel = ref.watch(travelListNotifierProvider).selectedTravel;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActionButton(
              icon: Icons.info_outline,
              label: '여행 정보',
              onPressed: () {
                if (travel == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TravelDetailPage(travelId: travel.travelId),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Icons.receipt_long_outlined,
              label: '사전 사용금액 등록',
              onPressed: () {
                if (travel == null) return;
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) =>
                //         // TravelPrepaymentCreateScreen(travelId: travel.travelId),
                //   ),
                // );
              },
            ),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Icons.calculate_outlined,
              label: '정산하기',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettlementScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Icons.logout,
              label: '여행 나가기',
              onPressed: () async {
                await showTravelOutDialog(context, () async {
                  try {
                    final travelId = ref
                        .read(travelListNotifierProvider)
                        .selectedTravel!
                        .travelId;

                    snackbarKey.currentState?.showSnackBar(
                      const SnackBar(content: Text('방 나가는 중 ..')),
                    );

                    await ref
                        .read(travelNotifierProvider.notifier)
                        .leaveTravel(travelId);

                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const BaseScreen()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('여행 나가기에 실패했습니다.')),
                      );
                    }
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 색은 건드리지 않고 모양/사이즈/간격만 통일한 공통 버튼
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56, // 모든 버튼 동일 높이
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          // 색상은 테마 기본값 사용 (변경 X)
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2, // 살짝만 띄움 (색 변화 없음)
          shadowColor: Colors.black26,
        ),
      ),
    );
  }
}

Future<void> showTravelOutDialog(
  BuildContext context,
  Future<void> Function() onOut,
) async {
  await showDialog<void>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: const Text('여행 나가기'),
        content: const Text('정말 여행을 나가시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await onOut();
            },
            child: const Text('나가기'),
          ),
        ],
      );
    },
  );
}
