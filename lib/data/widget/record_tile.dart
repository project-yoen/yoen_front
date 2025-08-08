// lib/ui/items/record_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yoen_front/data/model/record_response.dart';
import 'package:yoen_front/data/widget/responsive_shimmer_image.dart';

typedef RecordMenuAction = Future<void> Function(String action);

class RecordTile extends StatelessWidget {
  final RecordResponse record;
  final VoidCallback onTap; // 보통: 상세 다이얼로그 열기
  final RecordMenuAction? onMenuAction; // 'edit' / 'delete' 등
  final VoidCallback? onDeleteConfirm; // 삭제 확정시 실행(선택)

  const RecordTile({
    super.key,
    required this.record,
    required this.onTap,
    this.onMenuAction,
    this.onDeleteConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final recordTime = DateTime.parse(record.recordTime);
    final formattedTime = DateFormat('a h:mm', 'ko_KR').format(recordTime);

    Offset? tapPosition;

    return GestureDetector(
      onTapDown: (d) => tapPosition = d.globalPosition,
      child: InkWell(
        onTap: onTap,
        onLongPress: onMenuAction == null
            ? null
            : () async {
                if (tapPosition == null) return;
                final overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;

                final result = await showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(
                    tapPosition!.dx,
                    tapPosition!.dy,
                    overlay.size.width - tapPosition!.dx,
                    overlay.size.height - tapPosition!.dy,
                  ),
                  items: const [
                    PopupMenuItem(value: 'edit', child: Text('수정')),
                    PopupMenuItem(value: 'delete', child: Text('삭제')),
                  ],
                );

                if (result != null) await onMenuAction!(result);
              },
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.outlineVariant),
          ),
          child: Padding(
            // payment tile 과 동일한 여백 느낌
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 아이콘 + 제목 + 시간 pill
                Row(
                  children: [
                    _leadingIcon(c),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.title,
                        style: t.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    _timePill(formattedTime, c, t),
                  ],
                ),

                const SizedBox(height: 4),

                // 작성자
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: c.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '작성자: ${record.travelNickName}',
                        style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // 이미지 썸네일 (있을 때만)
                if (record.images.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 92, // payment 타일과 톤 맞춘 살짝 컴팩트한 높이
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: record.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: 1, // 정사각형 썸네일
                          child: ResponsiveShimmerImage(
                            imageUrl: record.images[i].imageUrl,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _leadingIcon(ColorScheme c) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: c.surfaceVariant.withOpacity(.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.camera_alt_outlined, size: 18, color: c.onSurface),
    );
  }

  Widget _timePill(String text, ColorScheme c, TextTheme t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceVariant.withOpacity(.5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Text(
        text,
        style: t.labelSmall?.copyWith(color: c.onSurfaceVariant),
      ),
    );
  }
}
