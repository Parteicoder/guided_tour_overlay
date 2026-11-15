import 'package:flutter/material.dart';

/// How an [ArrowRing] looks. Every value has a default, so
/// `const ArrowRingStyle()` is the standard look; set only what you want to
/// change.
@immutable
class ArrowRingStyle {
  /// Creates a style. All values are optional.
  const ArrowRingStyle({
    this.color = const Color(0xFFFF8A00),
    this.ringColor,
    this.labelColor,
    this.labelBackground,
    this.labelStyle,
    this.arrowSize = 36,
    this.ringWidth = 3,
    this.ringPadding = 8,
    this.hopDistance = 16,
    this.upIcon = Icons.arrow_upward,
    this.downIcon = Icons.arrow_downward,
  }) : assert(hopDistance >= 0),
       assert(arrowSize > 0),
       assert(ringWidth >= 0),
       assert(ringPadding >= 0);

  /// Color of the arrow, and the default for the ring and the label.
  final Color color;

  /// Color of the ring. Defaults to [color].
  final Color? ringColor;

  /// Color of the label text. Defaults to [color].
  final Color? labelColor;

  /// Fills a pill behind the label, for contrast on light or busy
  /// backgrounds. No background by default.
  final Color? labelBackground;

  /// Merged over the default label style (bold, 14 px).
  final TextStyle? labelStyle;

  /// Size of the arrow icon in logical pixels.
  final double arrowSize;

  /// Stroke width of the ring.
  final double ringWidth;

  /// Space between the target and the ring.
  final double ringPadding;

  /// How far the arrow hops, in logical pixels.
  final double hopDistance;

  /// Icon of the arrow that points up (target in the upper half).
  final IconData upIcon;

  /// Icon of the arrow that points down (target in the lower half).
  final IconData downIcon;
}

/// A hopping arrow with an optional label and a pulsing ring around [target].
///
/// Place it as a `Positioned.fill` child of a `Stack` that covers the same
/// area [target] is measured in. It ignores all pointer events, so the UI
/// underneath stays fully usable. An empty [target] draws nothing and runs no
/// animation.
///
/// The arrow sits above a target in the lower half of the area (pointing
/// down) and below a target in the upper half (pointing up). It hops towards
/// the target. When the system asks to reduce animations, the arrow and ring
/// are drawn without moving.
class ArrowRing extends StatefulWidget {
  /// Creates an arrow and ring around [target].
  const ArrowRing({
    super.key,
    required this.target,
    this.label,
    this.style = const ArrowRingStyle(),
  });

  /// The area to point at, in the coordinates of the surrounding stack.
  final Rect target;

  /// Short text next to the arrow, for example "Tap here".
  final String? label;

  /// Colors, sizes and icons.
  final ArrowRingStyle style;

  @override
  State<ArrowRing> createState() => _ArrowRingState();
}

class _ArrowRingState extends State<ArrowRing> with TickerProviderStateMixin {
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  bool _reduceMotion = false;

  static const double _gap = 8;
  static const double _labelWidth = 120;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncAnimations();
  }

  @override
  void didUpdateWidget(ArrowRing old) {
    super.didUpdateWidget(old);
    _syncAnimations();
  }

  void _syncAnimations() {
    final shouldRun = !widget.target.isEmpty && !_reduceMotion;
    if (shouldRun && !_hop.isAnimating) {
      _hop.repeat(reverse: true);
      _pulse.repeat();
    } else if (!shouldRun && _hop.isAnimating) {
      _hop.stop();
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    if (target.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox.expand(
        child: LayoutBuilder(
          builder: (context, box) {
            assert(
              box.hasBoundedWidth && box.hasBoundedHeight,
              'ArrowRing needs bounded constraints, '
              'use it as a Positioned.fill child of a Stack.',
            );
            final below = target.center.dy < box.maxHeight / 2;
            return AnimatedBuilder(
              animation: Listenable.merge([_hop, _pulse]),
              builder: (context, _) {
                final hop = _reduceMotion
                    ? 0.0
                    : Curves.easeInOut.transform(_hop.value) *
                          widget.style.hopDistance;
                // Distance from the target: gap plus the part of the hop
                // that has not been travelled yet, so the arrow hops towards
                // the target and never covers it.
                final distance = _gap + (widget.style.hopDistance - hop);
                final pulse = _reduceMotion ? 0.5 : _pulse.value;
                final ring = target.inflate(widget.style.ringPadding);
                final radius = ring.shortestSide / 2;
                final left = (target.center.dx - _labelWidth / 2).clamp(
                  0.0,
                  (box.maxWidth - _labelWidth).clamp(0.0, double.infinity),
                );
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fromRect(
                      rect: ring,
                      child: Opacity(
                        opacity: (1 - pulse).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 1 + 0.2 * pulse,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                              border: Border.all(
                                color:
                                    widget.style.ringColor ??
                                    widget.style.color,
                                width: widget.style.ringWidth,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: left,
                      width: _labelWidth,
                      top: below ? target.bottom + distance : null,
                      bottom: below
                          ? null
                          : box.maxHeight - target.top + distance,
                      child: ExcludeSemantics(child: _arrow(below)),
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
    final style = widget.style;
    final icon = Icon(
      pointsUp ? style.upIcon : style.downIcon,
      size: style.arrowSize,
      color: style.color,
    );
    Widget? text;
    if (widget.label != null) {
      text = Text(
        widget.label!,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: style.labelColor ?? style.color,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ).merge(style.labelStyle),
      );
      if (style.labelBackground != null) {
        text = DecoratedBox(
          decoration: BoxDecoration(
            color: style.labelBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: text,
          ),
        );
      }
    }
    // Own transparent Material: outside a Scaffold the text would otherwise
    // fall back to the red double-underlined error style.
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [if (pointsUp) icon, ?text, if (!pointsUp) icon],
      ),
    );
  }
}
