import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_tour_overlay/guided_tour_overlay.dart';

TourCard _card({
  VoidCallback? onBack,
  VoidCallback? onNext,
  VoidCallback? onSkip,
}) => TourCard(
  title: 'Title',
  text:
      'Some explanation text that is long enough to wrap onto more than '
      'one line when the screen is narrow.',
  progress: '1 of 3',
  onBack: onBack,
  onNext: onNext ?? () {},
  onSkip: onSkip ?? () {},
  backLabel: 'Back',
  nextLabel: 'Next',
  skipLabel: 'Skip',
);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  overlayStyleTests();
  group('TourCard', () {
    testWidgets('large text scale does not overflow on a narrow screen', (
      t,
    ) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: _card(onBack: () {}),
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('next, back and skip call their callbacks', (t) async {
      final calls = <String>[];
      await t.pumpWidget(
        _host(
          Align(
            alignment: Alignment.bottomCenter,
            child: _card(
              onBack: () => calls.add('back'),
              onNext: () => calls.add('next'),
              onSkip: () => calls.add('skip'),
            ),
          ),
        ),
      );
      await t.tap(find.text('Next'));
      await t.tap(find.text('Back'));
      await t.tap(find.text('Skip'));
      expect(calls, ['next', 'back', 'skip']);
    });

    testWidgets('back button is absent when onBack is null', (t) async {
      await t.pumpWidget(
        _host(Align(alignment: Alignment.bottomCenter, child: _card())),
      );
      expect(find.text('Back'), findsNothing);
      expect(find.text('Next'), findsOneWidget);
    });
  });

  group('TourCard landscape', () {
    testWidgets('long text at 2x scale in landscape does not overflow', (
      t,
    ) async {
      t.view.physicalSize = const Size(640, 320);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: TourOverlay(
                    card: TourCard(
                      title: 'A fairly long title for a step',
                      text: List.filled(
                        30,
                        'Long explanation sentence.',
                      ).join(' '),
                      progress: '2 of 5',
                      onBack: () {},
                      onNext: () {},
                      onSkip: () {},
                      backLabel: 'Back',
                      nextLabel: 'Next',
                      skipLabel: 'Skip',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('cardAlignment top keeps a bottom target tappable', (t) async {
    var taps = 0;
    final key = GlobalKey();
    t.view.physicalSize = const Size(400, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      _host(
        Stack(
          children: [
            Positioned(
              left: 300,
              bottom: 20,
              child: FloatingActionButton(
                key: key,
                onPressed: () => taps++,
                child: const Icon(Icons.add),
              ),
            ),
            Positioned.fill(
              child: TourOverlay(
                target: key,
                cardAlignment: Alignment.topCenter,
                card: _card(),
              ),
            ),
          ],
        ),
      ),
    );
    await t.pump();
    await t.tap(find.byKey(key));
    expect(taps, 1);
  });

  group('TourOverlay', () {
    testWidgets('arrow sits on the target', (t) async {
      final key = GlobalKey();
      await t.pumpWidget(
        _host(
          Stack(
            children: [
              Positioned(
                left: 100,
                top: 200,
                child: SizedBox(key: key, width: 80, height: 40),
              ),
              Positioned.fill(
                child: TourOverlay(
                  target: key,
                  arrowLabel: 'Here',
                  card: _card(),
                ),
              ),
            ],
          ),
        ),
      );
      await t.pump();
      final ring = t.widget<ArrowRing>(find.byType(ArrowRing));
      final real = t.getRect(find.byKey(key));
      expect((ring.target.center - real.center).distance, lessThan(1));
      expect(find.text('Here'), findsOneWidget);
    });

    testWidgets('target not built yet: only the card is shown', (t) async {
      final key = GlobalKey();
      await t.pumpWidget(
        _host(
          Stack(
            children: [
              Positioned.fill(
                child: TourOverlay(target: key, card: _card()),
              ),
            ],
          ),
        ),
      );
      await t.pump();
      expect(find.byType(ArrowRing), findsNothing);
      expect(find.text('Title'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('no target: only the card is shown', (t) async {
      await t.pumpWidget(
        _host(
          Stack(
            children: [Positioned.fill(child: TourOverlay(card: _card()))],
          ),
        ),
      );
      await t.pump();
      expect(find.byType(ArrowRing), findsNothing);
    });

    testWidgets('taps beside the card reach the app underneath', (t) async {
      var taps = 0;
      final key = GlobalKey();
      await t.pumpWidget(
        _host(
          Stack(
            children: [
              Positioned(
                left: 100,
                top: 100,
                child: ElevatedButton(
                  key: key,
                  onPressed: () => taps++,
                  child: const Text('Go'),
                ),
              ),
              Positioned.fill(
                child: TourOverlay(target: key, card: _card()),
              ),
            ],
          ),
        ),
      );
      await t.pump();
      await t.tap(find.text('Go'));
      expect(taps, 1);
    });

    testWidgets('arrow follows the target when the window changes size', (
      t,
    ) async {
      final key = GlobalKey();
      t.view.physicalSize = const Size(800, 600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        _host(
          Stack(
            children: [
              Center(child: SizedBox(key: key, width: 80, height: 40)),
              Positioned.fill(
                child: TourOverlay(target: key, card: _card()),
              ),
            ],
          ),
        ),
      );
      await t.pump();
      t.view.physicalSize = const Size(400, 900);
      await t.pump();
      await t.pump();
      final ring = t.widget<ArrowRing>(find.byType(ArrowRing));
      final real = t.getRect(find.byKey(key));
      expect((ring.target.center - real.center).distance, lessThan(1));
    });

    testWidgets('swapping the target key moves the arrow', (t) async {
      final a = GlobalKey();
      final b = GlobalKey();
      Widget build(GlobalKey target) => _host(
        Stack(
          children: [
            Positioned(
              left: 20,
              top: 100,
              child: SizedBox(key: a, width: 50, height: 50),
            ),
            Positioned(
              left: 300,
              top: 300,
              child: SizedBox(key: b, width: 50, height: 50),
            ),
            Positioned.fill(
              child: TourOverlay(target: target, card: _card()),
            ),
          ],
        ),
      );
      await t.pumpWidget(build(a));
      await t.pump();
      await t.pumpWidget(build(b));
      await t.pump();
      await t.pump();
      final ring = t.widget<ArrowRing>(find.byType(ArrowRing));
      expect(
        (ring.target.center - t.getRect(find.byKey(b)).center).distance,
        lessThan(1),
      );
    });
  });
}

void overlayStyleTests() {
  testWidgets('TourOverlay passes arrowStyle on to the arrow', (t) async {
    final key = GlobalKey();
    await t.pumpWidget(
      _host(
        Stack(
          children: [
            Positioned(
              left: 100,
              top: 400,
              child: SizedBox(key: key, width: 80, height: 40),
            ),
            Positioned.fill(
              child: TourOverlay(
                target: key,
                card: _card(),
                cardAlignment: Alignment.topCenter,
                arrowStyle: const ArrowRingStyle(
                  color: Color(0xFF123456),
                  downIcon: Icons.south,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await t.pump();
    expect(
      t.widget<Icon>(find.byIcon(Icons.south)).color,
      const Color(0xFF123456),
    );
  });
}
