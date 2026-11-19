import 'package:material_ui/material_ui.dart';

/// The explanation card of a tour step: progress, title, text and the
/// buttons "back", "next" and "skip".
///
/// All labels come from the caller, the package ships no texts. The card has
/// its own [Material] because the overlay usually sits outside a `Scaffold`.
class TourCard extends StatelessWidget {
  /// Creates a card for one tour step.
  const TourCard({
    super.key,
    required this.title,
    required this.text,
    required this.progress,
    required this.onNext,
    required this.onSkip,
    required this.nextLabel,
    required this.skipLabel,
    this.onBack,
    this.backLabel = '',
    this.color,
    this.elevation = 6,
  });

  /// Title of the step, shown as a header.
  final String title;

  /// Explanation text of the step.
  final String text;

  /// For example "2 of 5".
  final String progress;

  /// Back button is hidden when this is null (first step).
  final VoidCallback? onBack;

  /// Called when the user taps the "next" button.
  final VoidCallback onNext;

  /// Called when the user taps the "skip" button.
  final VoidCallback onSkip;

  /// Label of the "back" button.
  final String backLabel;

  /// Label of the "next" button, for example "Next" or "Done".
  final String nextLabel;

  /// Label of the "skip" button.
  final String skipLabel;

  /// Background of the card. Defaults to `colorScheme.surfaceContainerHigh`,
  /// one step lighter than the page, so the card stands out in dark mode too.
  final Color? color;

  /// Shadow depth of the card.
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        elevation: elevation,
        color: color ?? theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Everything above the buttons scrolls when the card is short
              // (landscape, big system font); the buttons always stay in view.
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(progress, style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Semantics(
                        header: true,
                        child: Text(title, style: theme.textTheme.titleMedium),
                      ),
                      const SizedBox(height: 6),
                      Text(text, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  TextButton(onPressed: onSkip, child: Text(skipLabel)),
                  if (onBack != null)
                    TextButton(onPressed: onBack, child: Text(backLabel)),
                  FilledButton(onPressed: onNext, child: Text(nextLabel)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
