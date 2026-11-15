import 'package:flutter/widgets.dart';

/// One step of a tour.
class TourStep {
  /// Creates a tour step.
  const TourStep({
    required this.id,
    required this.title,
    required this.text,
    this.target,
    this.arrowLabel,
  });

  /// Stable identifier, handed back in `onStepChanged`.
  final String id;

  /// Title of the step.
  final String title;

  /// Explanation text of the step.
  final String text;

  /// The widget to point at. Without a target only the card is shown.
  final GlobalKey? target;

  /// Short text next to the arrow.
  final String? arrowLabel;
}
