//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. See LICENSE file
// in root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class PodListHelper<T extends Object?> {
  //
  //
  //

  const PodListHelper();

  //
  //
  //

  TPodList<T> get pods;

  //
  //
  //

  /// Disposes all `Pod` objects in the list. This method should be called when
  /// the `Pod` objects are no longer needed, to release resources.
  void dispose() {
    for (final pod in pods) {
      pod?.dispose();
    }
  }

  //
  //
  //

  /// Disposes only those `Pod` objects in the list that are marked as
  /// temporary. This method is useful for selectively releasing resources used
  /// by temporary `Pod` objects.
  void disposeIfMarkedAsTemp() {
    for (final pod in pods) {
      pod?.disposeIfMarkedAsTemp();
    }
  }
}
