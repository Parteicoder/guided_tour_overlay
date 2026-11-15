import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_tour_overlay/guided_tour_overlay.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('empty target draws nothing and does not throw', (t) async {
    await t.pumpWidget(
      _host(
        const Stack(
          children: [
            Positioned.fill(
              child: ArrowRing(target: Rect.zero, label: 'Tap'),
            ),
          ],
        ),
      ),
    );
    expect(find.byType(Icon), findsNothing);
    expect(find.text('Tap'), findsNothing);
  });

  testWidgets('shows the label', (t) async {
    await t.pumpWidget(
      _host(
        const Stack(
          children: [
            Positioned.fill(
              child: ArrowRing(
                target: Rect.fromLTWH(100, 100, 80, 40),
                label: 'Tap here',
              ),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Tap here'), findsOneWidget);
  });

  testWidgets('arrow hops: position changes over time', (t) async {
    await t.pumpWidget(
      _host(
        const Stack(
          children: [
            Positioned.fill(
              child: ArrowRing(target: Rect.fromLTWH(100, 400, 80, 40)),
            ),
          ],
        ),
      ),
    );
    final before = t.getTopLeft(find.byType(Icon));
    await t.pump(const Duration(milliseconds: 600));
    final after = t.getTopLeft(find.byType(Icon));
    expect(after, isNot(before));
  });

  testWidgets(
    'arrow points down for a target in the lower half, up in the upper',
    (t) async {
      await t.pumpWidget(
        _host(
          const Stack(
            children: [
              Positioned.fill(
                child: ArrowRing(target: Rect.fromLTWH(100, 500, 80, 40)),
              ),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      await t.pumpWidget(
        _host(
          const Stack(
            children: [
              Positioned.fill(
                child: ArrowRing(target: Rect.fromLTWH(100, 20, 80, 40)),
              ),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    },
  );

  testWidgets('taps go through to the button underneath', (t) async {
    var taps = 0;
    await t.pumpWidget(
      _host(
        Stack(
          children: [
            Positioned(
              left: 100,
              top: 100,
              child: ElevatedButton(
                onPressed: () => taps++,
                child: const Text('Go'),
              ),
            ),
            const Positioned.fill(
              child: ArrowRing(
                target: Rect.fromLTWH(100, 100, 80, 40),
                label: 'Tap',
              ),
            ),
          ],
        ),
      ),
    );
    await t.tap(find.text('Go'));
    expect(taps, 1);
  });

  testWidgets('empty target runs no animation (pumpAndSettle finishes)', (
    t,
  ) async {
    await t.pumpWidget(
      _host(
        const Stack(
          children: [Positioned.fill(child: ArrowRing(target: Rect.zero))],
        ),
      ),
    );
    await t.pumpAndSettle();
  });

  testWidgets('a wide target gets a ring that hugs it, not a huge circle', (
    t,
  ) async {
    await t.pumpWidget(
      _host(
        const Stack(
          children: [
            Positioned.fill(
              child: ArrowRing(target: Rect.fromLTWH(20, 500, 360, 56)),
            ),
          ],
        ),
      ),
    );
    final ring = t.getRect(find.byType(Transform).first);
    expect(ring.width, lessThan(360 + 16 + 80));
    expect(ring.height, lessThan(56 + 16 + 40));
  });

  testWidgets(
    'arrow and label stay inside the screen for a target at the edge',
    (t) async {
      await t.pumpWidget(
        _host(
          const Stack(
            children: [
              Positioned.fill(
                child: ArrowRing(
                  target: Rect.fromLTWH(0, 500, 48, 48),
                  label: 'Left',
                ),
              ),
            ],
          ),
        ),
      );
      final r = t.getRect(find.text('Left'));
      expect(r.left, greaterThanOrEqualTo(0));
      final screen = t.view.physicalSize / t.view.devicePixelRatio;
      expect(r.right, lessThanOrEqualTo(screen.width));
    },
  );

  testWidgets('arrow never covers the target while hopping', (t) async {
    const target = Rect.fromLTWH(100, 500, 80, 40);
    await t.pumpWidget(
      _host(
        const Stack(
          children: [
            Positioned.fill(
              child: ArrowRing(target: target, label: 'x'),
            ),
          ],
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 100));
      expect(
        t.getRect(find.byType(Icon)).bottom,
        lessThanOrEqualTo(target.top),
      );
    }
  });

  testWidgets('reduced motion: arrow and ring stand still', (t) async {
    await t.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: const Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: ArrowRing(target: Rect.fromLTWH(100, 400, 80, 40)),
              ),
            ],
          ),
        ),
      ),
    );
    final before = t.getTopLeft(find.byType(Icon));
    await t.pump(const Duration(milliseconds: 600));
    expect(t.getTopLeft(find.byType(Icon)), before);
    await t.pumpAndSettle();
  });

  testWidgets('label outside a Scaffold has no error underline', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: ArrowRing(
                target: Rect.fromLTWH(100, 100, 80, 40),
                label: 'Tap',
              ),
            ),
          ],
        ),
      ),
    );
    final style = t.widget<Text>(find.text('Tap'));
    expect(
      DefaultTextStyle.of(t.element(find.text('Tap'))).style.decoration,
      isNot(TextDecoration.underline),
    );
    expect(style.data, 'Tap');
  });
}
