import 'package:flutter/material.dart';

/// A hopping arrow with an optional label and a pulsing ring around [target].
///
/// Place it as a `Positioned.fill` child of a `Stack` that covers the same
/// area [target] is measured in. It ignores all pointer events, so the UI
/// underneath stays fully usable. An empty [target] draws nothing.
class ArrowRing extends StatefulWidget {
  const ArrowRing({
    super.key,
    required this.target,
    this.label,
    this.color = const Color(0xFFFF8A00),
    this.hopDistance = 16,
  });

  /// The area to point at, in the coordinates of the surrounding stack.
  final Rect target;

  /// Short text next to the arrow, for example "Tap here".
  final String? label;

  /// Color of the arrow, the label and the ring.
  final Color color;

  /// How far the arrow hops, in logical pixels.
  final double hopDistance;

  @override
  State<ArrowRing> createState() => _ArrowRingState();
}

class _ArrowRingState extends State<ArrowRing> with TickerProviderStateMixin {
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _hop.dispose();
    _pulse.dispose();
    super.dispose();
  }

  static const double _arrowSize = 36;
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    if (target.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, box) {
            final below = target.center.dy < box.maxHeight / 2;
            return AnimatedBuilder(
              animation: Listenable.merge([_hop, _pulse]),
              builder: (context, _) {
                final hop = Curves.easeInOut.transform(_hop.value) *
                    widget.hopDistance;
                final pulse = _pulse.value;
                final ringSize = (target.longestSide + 16);
                final scale = 0.9 + 0.6 * pulse;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: target.center.dx - ringSize / 2,
                      top: target.center.dy - ringSize / 2,
                      width: ringSize,
                      height: ringSize,
                      child: Opacity(
                        opacity: (1 - pulse).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: scale,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: widget.color, width: 3),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: target.center.dx - 60,
                      width: 120,
                      top: below
                          ? target.bottom + _gap + hop
                          : null,
                      bottom: below
                          ? null
                          : box.maxHeight - target.top + _gap - hop,
                      child: _arrow(below),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _arrow(bool pointsUp) {
    final icon = Icon(
      pointsUp ? Icons.arrow_upward : Icons.arrow_downward,
      size: _arrowSize,
      color: widget.color,
    );
    final text = widget.label == null
        ? null
        : Text(
            widget.label!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: widget.color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pointsUp) icon,
        ?text,
        if (!pointsUp) icon,
      ],
    );
  }
}
