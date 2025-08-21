import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:yoen_front/data/widget/image_cache_manager.dart';

class EditableAvatar extends StatelessWidget {
  final double size;
  final String? imageUrl; // 서버 이미지
  final File? localFile; // 갤러리/카메라 선택 파일
  final String fallbackText; // 이니셜
  final VoidCallback? onTap;

  const EditableAvatar({
    super.key,
    required this.size,
    this.imageUrl,
    this.localFile,
    required this.fallbackText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surfaceVariant;

    Widget child;
    if (localFile != null) {
      child = Image.file(
        localFile!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if ((imageUrl ?? '').isNotEmpty) {
      child = CachedNetworkImage(
        cacheManager: imageCacheManager,
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // 스피너 제거: 가벼운 플레이스홀더만 사용
        placeholder: (_, __) => _Skeleton(size: size, color: bg),
        errorWidget: (_, __, ___) =>
            _Initials(size: size, text: fallbackText, bg: bg),
        // 필요 시 메모리 최적화
        // memCacheWidth: 800, memCacheHeight: 800,
      );
    } else {
      child = _Initials(size: size, text: fallbackText, bg: bg);
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(width: size, height: size, child: child),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double size;
  final Color color;
  const _Skeleton({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    // 단색 박스(광택/애니메이션 없음)
    return Container(width: size, height: size, color: color);
  }
}

class _Initials extends StatelessWidget {
  final double size;
  final String text;
  final Color bg;
  const _Initials({required this.size, required this.text, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bg,
      alignment: Alignment.center,
      child: Text(
        (text.isNotEmpty ? text[0] : 'U').toUpperCase(),
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: size * .42),
      ),
    );
  }
}
