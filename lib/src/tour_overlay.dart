import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'arrow_ring.dart';

/// Floats an [ArrowRing] on [target] and a [card] at the bottom above the
/// live UI. Everything except the card ignores pointer events, so the app
/// underneath stays usable.
///
/// Place it as a `Positioned.fill` child of a `Stack` above the app. If
/// [target] is null or not built (not attached to a render object), only the
/// card is shown.
class TourOverlay extends StatefulWidget {
  const TourOverlay({
    super.key,
    required this.card,
    this.target,
    this.arrowLabel,
    this.cardMargin = const EdgeInsets.all(16),
    this.maxCardWidth = 480,
  });

  final Widget card;
  final GlobalKey? target;
  final String? arrowLabel;

  /// Space around the card. The caller adds the height of a bottom
  /// navigation bar and the safe area here.
  final EdgeInsets cardMargin;
  final double maxCardWidth;

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay> {
  Rect _rect = Rect.zero;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(TourOverlay old) {
    super.didUpdateWidget(old);
    _schedule();
  }

  // Reads the target position after layout, once per frame while mounted.
  // The arrow animation keeps frames coming, so a moving target is followed.
  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      final next = _measure();
      if (next != _rect) setState(() => _rect = next);
      _schedule();
    });
  }

  Rect _measure() {
    final targetBox = widget.target?.currentContext?.findRenderObject();
    final ownBox = context.findRenderObject();
    if (targetBox is! RenderBox ||
        ownBox is! RenderBox ||
        !targetBox.attached ||
        !ownBox.attached ||
        !targetBox.hasSize ||
        !ownBox.hasSize) {
      return Rect.zero;
    }
    final topLeft =
        ownBox.globalToLocal(targetBox.localToGlobal(Offset.zero));
    return topLeft & targetBox.size;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (!_rect.isEmpty)
          Positioned.fill(
            child: ArrowRing(target: _rect, label: widget.arrowLabel),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: 0,
          child: Padding(
            padding: widget.cardMargin,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: widget.maxCardWidth),
                child: widget.card,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
