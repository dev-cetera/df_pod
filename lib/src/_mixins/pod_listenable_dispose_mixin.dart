//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'dispose_mixin.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin that provides disposal management for Pods.
@internal
mixin PodListenableDisposeMixin<T> implements PodListenable<T>, DisposeMixin {
  /// A flag indicating whether the Pod has been disposed.
  bool _isDisposed = false;

  /// Whether this [Pod] has been disposed of or not.
  @nonVirtual
  bool get isDisposed => this._isDisposed;

  /// This method is used internally and is meant to be called by the `dispose`
  /// method of the class that implements this [PodListenableDisposeMixin]. Do not call
  /// this method directly.
  ///
  /// ### Example:
  ///
  /// ```
  /// class PodNotifier<T> extends ValueNotifier<T> with PodDisposableMixin<T> {
  ///   @override
  ///   void dispose() {
  ///     super.maybeDispose(
  ///       super.dispose,
  ///     );
  ///   );
  /// }
  /// ```
  @nonVirtual
  @protected
  void maybeDispose(VoidCallback dispose) {
    if (!_isDisposed) {
      dispose();
      this._isDisposed = true;
    } else {
      debugPrint(
        '[df_pod] Pod already disposed. This is not a problem but indicates '
        'that the dispose method was called more than once. Ensure that '
        'dispose is only called when necessary to avoid redundant operations.',
      );
    }
  }
}
