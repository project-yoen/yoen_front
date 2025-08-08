import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

// 1) 스켈레톤 (파일 카드 더미)
class FileCardSkeleton extends StatelessWidget {
  const FileCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceVariant.withOpacity(.6);
    final highlight = Theme.of(
      context,
    ).colorScheme.surfaceVariant.withOpacity(.85);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          // 파일 썸네일 더미
          Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(8),
              ),
              color: base,
            ),
          ),
          const SizedBox(width: 12),
          // 텍스트 라인 더미 2~3줄
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: base,
                  highlightColor: highlight,
                  child: Container(
                    height: 14,
                    width: 180,
                    color: base,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                ),
                Shimmer.fromColors(
                  baseColor: base,
                  highlightColor: highlight,
                  child: Container(height: 12, width: 120, color: base),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 액션 버튼 자리 더미
          Shimmer.fromColors(
            baseColor: base,
            highlightColor: highlight,
            child: Container(width: 24, height: 24, color: base),
          ),
        ],
      ),
    );
  }
}
