import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yoen_front/data/widget/image_cache_manager.dart';

class ResponsiveShimmerImage extends StatelessWidget {
  final String imageUrl;
  final double aspectRatio; // 예: 16 / 9
  final double borderRadius;

  const ResponsiveShimmerImage({
    super.key,
    required this.imageUrl,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // URL 없을 때도 안전하게 스켈레톤 반환
    if (imageUrl.isEmpty) {
      return _Skeleton(aspectRatio: aspectRatio, borderRadius: borderRadius);
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          cacheManager: imageCacheManager,
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          fadeInDuration: const Duration(milliseconds: 250),
          placeholderFadeInDuration: const Duration(milliseconds: 100),

          // 메모리 사용 최적화(선택): 해상도 제한
          // memCacheWidth: 1600, memCacheHeight: 1600,
          placeholder: (context, url) =>
              _Skeleton(aspectRatio: aspectRatio, borderRadius: borderRadius),

          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(
              Icons.broken_image_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double aspectRatio;
  final double borderRadius;
  const _Skeleton({required this.aspectRatio, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    // 대비가 더 큰 회색 톤 설정
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
