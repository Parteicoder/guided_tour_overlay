import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_tour_overlay/guided_tour_overlay.dart';

TourCard _card({Color? color}) => TourCard(
  title: 'Title',
  text: 'A long explanation. ' * 20,
  progress: '1 of 3',
  onNext: () {},
  onSkip: () {},
  onBack: () {},
  backLabel: 'Back',
  nextLabel: 'Next',
  skipLabel: 'Skip',
  color: color,
);

Material _material(WidgetTester t) => t.widget<Material>(
  find
      .descendant(of: find.byType(TourCard), matching: find.byType(Material))
      .first,
);

void main() {
  testWidgets('default color is one step lighter than the background', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Scaffold(body: _card()),
      ),
    );
    final scheme = Theme.of(t.element(find.byType(Scaffold))).colorScheme;
    expect(_material(t).color, scheme.surfaceContainerHigh);
  });

  testWidgets('color can be changed', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: _card(color: const Color(0xFF123456))),
      ),
    );
    expect(_material(t).color, const Color(0xFF123456));
  });

  testWidgets(
    'little height and big text: no overflow, buttons stay reachable',
    (t) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(800, 300);
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
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: _card(),
              ),
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      await t.tap(find.text('Next'));
      await t.tap(find.text('Skip'));
    },
  );
}
