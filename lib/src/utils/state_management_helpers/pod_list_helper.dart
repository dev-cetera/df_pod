//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_type/df_type.dart';

import '/src/_index.g.dart';

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
      letAsOrNull<PodDisposableMixin>(pod)?.dispose();
    }
  }

  //
  //
  //

  /// Disposes only those `Pod` objects in the list that are marked as
  /// temporary. This method is useful for selectively releasing resources used
  /// by temporary `Pod` objects.
  void disposeIfTemp() {
    for (final pod in pods) {
      letAsOrNull<PodDisposableMixin>(pod)?.disposeIfTemp();
    }
  }
}
