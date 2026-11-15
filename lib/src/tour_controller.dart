import 'package:flutter/foundation.dart';

import 'tour_step.dart';
import 'tour_storage.dart';

/// Runs a tour: which step is current, next, back, skip.
///
/// The state changes synchronously, so a fast double tap on "next" moves two
/// steps and never the same step twice. Errors from [storage] and from the
/// callbacks are caught: a failing disk or a buggy callback never stops the
/// tour.
class TourController extends ChangeNotifier {
  TourController({
    required this.steps,
    this.storage,
    this.onStepChanged,
    this.onFinished,
    this.onSkipped,
  });

  final List<TourStep> steps;
  final TourStorage? storage;

  /// Called after every step change, for example to switch a tab.
  final void Function(int index, TourStep step)? onStepChanged;

  /// Called when the last step was left with "next".
  final VoidCallback? onFinished;

  /// Called when the tour was skipped.
  final VoidCallback? onSkipped;

  int? _index;

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
    if (i == null) return;
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
    if (i == null || i == 0) return;
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
    notifyListeners();
    final step = steps[index];
    _guardSync(() => onStepChanged?.call(index, step));
    await _guard(() => storage?.saveStep(index));
  }

  Future<void> _guard(Future<void>? Function() action) async {
    try {
      await action();
    } catch (e, s) {
      debugPrint('guided_tour_overlay: storage error: $e\n$s');
    }
  }

  void _guardSync(VoidCallback? action) {
    try {
      action?.call();
    } catch (e, s) {
      debugPrint('guided_tour_overlay: callback error: $e\n$s');
    }
  }
}
