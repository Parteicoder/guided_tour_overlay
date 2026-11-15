# guided_tour_overlay

A guided tour for Flutter apps that only **shows**, never blocks.

A hopping arrow, a pulsing ring and an explanation card float above your live UI. Nothing is dimmed or locked: taps always reach the app underneath, and the user can skip at any time. You decide what happens on each step, for example switching a tab.

## What you get

- `ArrowRing`: hopping arrow with an optional label and a pulsing ring around a rectangle. Ignores all pointer events, stands still when the system asks to reduce animations.
- `TourCard`: explanation card with progress, title, text and "back", "next" and "skip" buttons. All labels come from you, the package ships no texts.
- `TourOverlay`: puts the arrow on a target (found through a `GlobalKey`, followed while it moves) and the card at the bottom.
- `TourController`: current step, `next`, `back`, `skip`, callbacks per step, double taps never skip a step, errors from storage or callbacks never stop the tour.
- `TourStorage`: a small interface to keep progress. The package stores nothing itself.

## Usage

```dart
final plusKey = GlobalKey();
final controller = TourController(
  steps: [
    TourStep(
      id: 'plus',
      title: 'Add something',
      text: 'Tap the plus to create a new entry.',
      target: plusKey,
      arrowLabel: 'Here',
    ),
    const TourStep(id: 'done', title: 'That is it', text: 'Enjoy the app.'),
  ],
  onStepChanged: (index, step) {
    // For example: switch to the tab that belongs to this step.
  },
);

// Above your app, inside a Stack:
ListenableBuilder(
  listenable: controller,
  builder: (context, _) {
    final step = controller.current;
    if (step == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: TourOverlay(
        target: step.target,
        arrowLabel: step.arrowLabel,
        cardMargin: const EdgeInsets.all(16),
        card: TourCard(
          title: step.title,
          text: step.text,
          progress: '${controller.index! + 1} of ${controller.steps.length}',
          backLabel: 'Back',
          nextLabel: 'Next',
          skipLabel: 'Skip',
          onBack: controller.index == 0 ? null : controller.back,
          onNext: controller.next,
          onSkip: controller.skip,
        ),
      ),
    );
  },
);

controller.start();
```

Pass a `TourStorage` to `TourController` to remember the step and whether the tour is done.

## License

MIT
