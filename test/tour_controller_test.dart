import 'package:flutter_test/flutter_test.dart';
import 'package:guided_tour_overlay/guided_tour_overlay.dart';

class _Storage implements TourStorage {
  final saved = <int>[];
  int finished = 0;
  bool throwOnSave = false;
  bool throwOnFinish = false;

  @override
  Future<int> loadStep() async => saved.isEmpty ? 0 : saved.last;

  @override
  Future<void> saveStep(int step) async {
    if (throwOnSave) throw Exception('disk full');
    saved.add(step);
  }

  @override
  Future<void> finish() async {
    if (throwOnFinish) throw Exception('disk full');
    finished++;
  }
}

List<TourStep> _steps(int n) => [
      for (var i = 0; i < n; i++)
        TourStep(id: 's$i', title: 'T$i', text: 'text $i'),
    ];

void main() {
  test('next walks through the steps, the end calls onFinished and finish',
      () async {
    final storage = _Storage();
    var finished = 0;
    final c = TourController(
      steps: _steps(3),
      storage: storage,
      onFinished: () => finished++,
    );
    await c.start();
    expect(c.running, isTrue);
    expect(c.index, 0);
    await c.next();
    await c.next();
    expect(c.index, 2);
    expect(c.current?.id, 's2');
    await c.next();
    expect(c.running, isFalse);
    expect(c.index, isNull);
    expect(finished, 1);
    expect(storage.finished, 1);
    expect(storage.saved, [0, 1, 2]);
  });

  test('a fast double next does not skip a step', () async {
    final c = TourController(steps: _steps(4), storage: _Storage());
    await c.start();
    final a = c.next();
    final b = c.next();
    await Future.wait([a, b]);
    expect(c.index, 2, reason: 'two calls are two taps: 0 to 1 to 2');
  });

  test('a double next on the last step finishes only once', () async {
    final storage = _Storage();
    var finished = 0;
    final c = TourController(
      steps: _steps(1),
      storage: storage,
      onFinished: () => finished++,
    );
    await c.start();
    await Future.wait([c.next(), c.next()]);
    expect(finished, 1);
    expect(storage.finished, 1);
  });

  test('back on the first step does nothing', () async {
    final c = TourController(steps: _steps(3), storage: _Storage());
    await c.start();
    await c.back();
    expect(c.index, 0);
    await c.next();
    await c.back();
    expect(c.index, 0);
  });

  test('skip cleans up and calls onSkipped, not onFinished', () async {
    final storage = _Storage();
    var skipped = 0, finished = 0;
    final c = TourController(
      steps: _steps(3),
      storage: storage,
      onSkipped: () => skipped++,
      onFinished: () => finished++,
    );
    await c.start();
    await c.skip();
    expect(c.running, isFalse);
    expect(c.index, isNull);
    expect(skipped, 1);
    expect(finished, 0);
    expect(storage.finished, 1);
  });

  test('onStepChanged fires on every change with index and step', () async {
    final seen = <String>[];
    final c = TourController(
      steps: _steps(3),
      onStepChanged: (i, s) => seen.add('$i:${s.id}'),
    );
    await c.start();
    await c.next();
    await c.back();
    expect(seen, ['0:s0', '1:s1', '0:s0']);
  });

  test('storage throws on save: the tour keeps running', () async {
    final storage = _Storage()..throwOnSave = true;
    final c = TourController(steps: _steps(3), storage: storage);
    await c.start();
    await c.next();
    expect(c.index, 1);
    expect(c.running, isTrue);
  });

  test('storage throws on finish: tour still ends and calls onFinished',
      () async {
    final storage = _Storage()..throwOnFinish = true;
    var finished = 0;
    final c = TourController(
      steps: _steps(1),
      storage: storage,
      onFinished: () => finished++,
    );
    await c.start();
    await c.next();
    expect(c.running, isFalse);
    expect(finished, 1);
  });

  test('a throwing onStepChanged does not break the tour', () async {
    final c = TourController(
      steps: _steps(2),
      onStepChanged: (_, _) => throw StateError('boom'),
    );
    await c.start();
    await c.next();
    expect(c.index, 1);
  });

  test('start(from: 2) begins there, an out-of-range value is clamped',
      () async {
    final c = TourController(steps: _steps(3));
    await c.start(from: 2);
    expect(c.index, 2);
    await c.start(from: 99);
    expect(c.index, 2);
    await c.start(from: -4);
    expect(c.index, 0);
  });

  test('start with no steps leaves running false', () async {
    final c = TourController(steps: const []);
    await c.start();
    expect(c.running, isFalse);
    expect(c.current, isNull);
  });

  test('next, back and skip before start do nothing', () async {
    var skipped = 0;
    final c = TourController(steps: _steps(2), onSkipped: () => skipped++);
    await c.next();
    await c.back();
    await c.skip();
    expect(c.running, isFalse);
    expect(skipped, 0);
  });

  test('notifies listeners on every change', () async {
    final c = TourController(steps: _steps(2));
    var n = 0;
    c.addListener(() => n++);
    await c.start();
    await c.next();
    await c.next();
    expect(n, 3);
  });

  test('dispose while a save is pending causes no error', () async {
    final c = TourController(steps: _steps(2), storage: _Storage());
    await c.start();
    final f = c.next();
    c.dispose();
    await f;
  });
}
