import 'package:flutter/material.dart';
import 'package:guided_tour_overlay/guided_tour_overlay.dart';

void main() => runApp(const MaterialApp(home: Demo()));

class Demo extends StatefulWidget {
  const Demo({super.key});

  @override
  State<Demo> createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  final _fabKey = GlobalKey();
  late final TourController _tour = TourController(
    steps: [
      TourStep(
        id: 'fab',
        title: 'Add something',
        text: 'Tap the button to create a new entry.',
        target: _fabKey,
        arrowLabel: 'Here',
      ),
      const TourStep(id: 'done', title: 'That is it', text: 'Enjoy the app.'),
    ],
  );

  @override
  void dispose() {
    _tour.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('Guided tour')),
          body: Center(
            child: FilledButton(
              onPressed: _tour.start,
              child: const Text('Start tour'),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            key: _fabKey,
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
        ),
        ListenableBuilder(
          listenable: _tour,
          builder: (context, _) {
            final step = _tour.current;
            if (step == null) return const SizedBox.shrink();
            return Positioned.fill(
              child: TourOverlay(
                target: step.target,
                arrowLabel: step.arrowLabel,
                cardAlignment: Alignment.topCenter,
                card: TourCard(
                  title: step.title,
                  text: step.text,
                  progress: '${_tour.index! + 1} of ${_tour.steps.length}',
                  backLabel: 'Back',
                  nextLabel: 'Next',
                  skipLabel: 'Skip',
                  onBack: _tour.index == 0 ? null : _tour.back,
                  onNext: _tour.next,
                  onSkip: _tour.skip,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
