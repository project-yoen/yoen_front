import 'package:flutter/material.dart';

class ProgressBadge extends StatefulWidget {
  final String label; // 표시할 문자열
  final Duration dotAnimationDuration; // 도트 깜빡이는 속도

  const ProgressBadge({
    super.key,
    required this.label,
    this.dotAnimationDuration = const Duration(milliseconds: 400),
  });

  @override
  State<ProgressBadge> createState() => _ProgressBadgeState();
}

class _ProgressBadgeState extends State<ProgressBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.dotAnimationDuration,
    )..repeat(reverse: true);

    _opacity = Tween(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(int index) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 14.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 도트 애니메이션
          Row(
            children: List.generate(
              3,
              (i) => Padding(
                padding: EdgeInsets.only(right: i == 2 ? 8 : 4),
                child: _buildDot(i),
              ),
            ),
          ),
          // 문자열 + 말줄임표 자동 추가
          Text(
            '${widget.label}…',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
