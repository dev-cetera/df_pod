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

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin that adds lifecycle management to the [Pod].
mixin PodDisposableMixin<T> implements PodListenable<T>, DisposeMixin {
  //
  //
  //

  /// Indicates whether this Pod is marked as "temporary". Temporary Pods are
  /// automatically disposed by supported builders like [PodBuilder] when they
  /// are removed from the widget tree.
  bool get temp;

  /// Indicates whether this Pod is marked as "disposable". Disposable Pods can
  /// be disposed of, whereas non-disposable Pods will throw a
  /// [DoNotDisposePodException] if [dispose] is called on them.
  ///
  /// Marking pods as non-disposable is useful for globally defined Pods, to
  /// prevent accidental disposal and ensuring their availability as long as
  /// the app is running.
  bool get disposable;

  /// A flag indicating whether the Pod has been disposed.
  bool _isDisposed = false;

  /// Whether this [Pod] has been disposed of or not.
  @nonVirtual
  bool get isDisposed => this._isDisposed;

  /// Disposes this [Pod] and removes all listeners if it is marked as [temp].
  ///
  /// This method is automatically called by supported builders like
  /// [PodBuilder].
  ///
  /// Custom widgets that accept a [Pod] as a parameter can leverage this method
  /// to automatically manage the lifecycle of temporary Pods. By calling this
  /// method in the widget's dispose function, it ensures that temporary Pods
  /// are appropriately disposed of when the widget itself is disposed,
  /// maintaining resource efficiency and avoiding memory leaks.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// @override
  /// void dispose() {
  ///   super.dispose();
  ///   myPod.disposeIfMarkedAsTemp();
  /// }
  /// ```
  @nonVirtual
  void disposeIfTemp() {
    if (temp) {
      dispose();
    }
  }

  /// This method is used internally and is meant to be called by the `dispose`
  /// method of the class that implements this [PodDisposableMixin]. Do not call
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
      if (disposable) {
        dispose();
        this._isDisposed = true;
      } else {
        throw DoNotDisposePodException();
      }
    } else {
      debugPrint('Pod already disposed.');
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class DoNotDisposePodException extends PodException {
  DoNotDisposePodException()
      : super(
          '"dispose" was called on a Pod that was explicitly maked as non-disposable.',
        );
}
