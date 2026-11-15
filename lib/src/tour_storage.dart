/// Where a tour keeps its progress. The package stores nothing itself, the
/// app provides the implementation (for example on top of shared_preferences).
abstract class TourStorage {
  /// The step to resume from, 0 if nothing was saved.
  Future<int> loadStep();

  /// Called every time the tour moves to [step].
  Future<void> saveStep(int step);

  /// Called when the tour ends, finished or skipped.
  Future<void> finish();
}
