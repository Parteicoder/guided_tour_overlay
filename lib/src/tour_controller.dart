import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'tour_step.dart';
import 'tour_storage.dart';

/// Runs a tour: which step is current, next, back, skip.
///
/// The state changes synchronously. A second `next` or `back` within
/// [tapGuard] of the last step change (measured with `clock`, real time by
/// default) is ignored, so a fast double tap never
/// skips a step. Errors from [storage] and from the callbacks are caught and
/// reported through [FlutterError.reportError]: a failing disk or a buggy
/// callback never stops the tour.
class TourController extends ChangeNotifier {
  TourController({
    required List<TourStep> steps,
    this.storage,
    this.onStepChanged,
    this.onFinished,
    this.onSkipped,
    this.tapGuard = const Duration(milliseconds: 350),
    DateTime Function()? clock,
  }) : steps = List.unmodifiable(steps),
       _now = clock ?? DateTime.now;

  final List<TourStep> steps;

  /// Ignore `next` and `back` calls that follow a step change this closely.
  final Duration tapGuard;

  // Injectable so an app's tests do not have to wait in real time.
  final DateTime Function() _now;
  final TourStorage? storage;

  /// Called after every step change, for example to switch a tab.
  final void Function(int index, TourStep step)? onStepChanged;

  /// Called when the last step was left with "next".
  final VoidCallback? onFinished;

  /// Called when the tour was skipped.
  final VoidCallback? onSkipped;

  int? _index;
  DateTime? _lastChange;

  bool get _tooSoon {
    final last = _lastChange;
    return last != null && _now().difference(last) < tapGuard;
  }

  bool get running => _index != null;
  int? get index => _index;
  TourStep? get current => _index == null ? null : steps[_index!];

  /// Starts the tour at step [from], clamped to the available steps.
  Future<void> start({int from = 0}) async {
    if (steps.isEmpty) return;
    await _goTo(from.clamp(0, steps.length - 1));
  }

  /// Goes to the next step. On the last step the tour ends and [onFinished]
  /// is called.
  Future<void> next() async {
    final i = _index;
    if (i == null || _tooSoon) return;
    if (i >= steps.length - 1) {
      _index = null;
      notifyListeners();
      await _guard(() => storage?.finish());
      _guardSync(onFinished);
      return;
    }
    await _goTo(i + 1);
  }

  /// Goes to the previous step. Does nothing on the first step.
  Future<void> back() async {
    final i = _index;
    if (i == null || i == 0 || _tooSoon) return;
    await _goTo(i - 1);
  }

  /// Ends the tour early and calls [onSkipped].
  Future<void> skip() async {
    if (_index == null) return;
    _index = null;
    notifyListeners();
    await _guard(() => storage?.finish());
    _guardSync(onSkipped);
  }

  Future<void> _goTo(int index) async {
    _index = index;
    _lastChange = _now();
    notifyListeners();
    final step = steps[index];
    // Save first, then the callback: a callback that ends the tour must not
    // be followed by a stale saveStep.
    final saved = _guard(() => storage?.saveStep(index));
    _guardSync(() => onStepChanged?.call(index, step));
    await saved;
  }

  Future<void> _guard(Future<void>? Function() action) async {
    try {
      await action();
    } catch (e, s) {
      _report(e, s, 'storage');
    }
  }

  void _guardSync(VoidCallback? action) {
    try {
      action?.call();
    } catch (e, s) {
      _report(e, s, 'callback');
    }
  }

  void _report(Object e, StackTrace s, String what) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: e,
        stack: s,
        library: 'guided_tour_overlay',
        context: ErrorDescription('while calling the $what of a tour'),
      ),
    );
  }
}
