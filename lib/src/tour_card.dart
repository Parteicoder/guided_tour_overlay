import 'package:flutter/material.dart';

/// The explanation card of a tour step: progress, title, text and the
/// buttons "back", "next" and "skip".
///
/// All labels come from the caller, the package ships no texts. The card has
/// its own [Material] because the overlay usually sits outside a `Scaffold`.
class TourCard extends StatelessWidget {
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
  });

  final String title;
  final String text;

  /// For example "2 of 5".
  final String progress;

  /// Back button is hidden when this is null (first step).
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final String backLabel;
  final String nextLabel;
  final String skipLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 6,
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(progress, style: theme.textTheme.labelSmall),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Flexible(
              child: SingleChildScrollView(
                child: Text(text, style: theme.textTheme.bodyMedium),
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
    );
  }
}
