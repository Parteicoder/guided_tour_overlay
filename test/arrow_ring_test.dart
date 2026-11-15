import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guided_tour_overlay/guided_tour_overlay.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('empty target draws nothing and does not throw', (t) async {
    await t.pumpWidget(_host(const Stack(children: [
      Positioned.fill(child: ArrowRing(target: Rect.zero, label: 'Tap')),
    ])));
    expect(find.byType(Icon), findsNothing);
    expect(find.text('Tap'), findsNothing);
  });

  testWidgets('shows the label', (t) async {
    await t.pumpWidget(_host(const Stack(children: [
      Positioned.fill(
        child: ArrowRing(target: Rect.fromLTWH(100, 100, 80, 40), label: 'Tap here'),
      ),
    ])));
    expect(find.text('Tap here'), findsOneWidget);
  });

  testWidgets('arrow hops: position changes over time', (t) async {
    await t.pumpWidget(_host(const Stack(children: [
      Positioned.fill(
        child: ArrowRing(target: Rect.fromLTWH(100, 400, 80, 40)),
      ),
    ])));
    final before = t.getTopLeft(find.byType(Icon));
    await t.pump(const Duration(milliseconds: 600));
    final after = t.getTopLeft(find.byType(Icon));
    expect(after, isNot(before));
  });

  testWidgets('arrow points down for a target in the lower half, up in the upper',
      (t) async {
    await t.pumpWidget(_host(const Stack(children: [
      Positioned.fill(
        child: ArrowRing(target: Rect.fromLTWH(100, 500, 80, 40)),
      ),
    ])));
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    await t.pumpWidget(_host(const Stack(children: [
      Positioned.fill(
        child: ArrowRing(target: Rect.fromLTWH(100, 20, 80, 40)),
      ),
    ])));
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets('taps go through to the button underneath', (t) async {
    var taps = 0;
    await t.pumpWidget(_host(Stack(children: [
      Positioned(
        left: 100,
        top: 100,
        child: ElevatedButton(onPressed: () => taps++, child: const Text('Go')),
      ),
      const Positioned.fill(
        child: ArrowRing(target: Rect.fromLTWH(100, 100, 80, 40), label: 'Tap'),
      ),
    ])));
    await t.tap(find.text('Go'));
    expect(taps, 1);
  });
}
