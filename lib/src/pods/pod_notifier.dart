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
import 'package:flutter/widgets.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An enhanced alternative to [ValueNotifier] that provides additional
/// lifecycle management capabilities through the [PodDisposableMixin].
class PodNotifier<T> extends ValueNotifier<T> with PodDisposableMixin<T> {
  //
  //
  //

  @override
  final bool disposable;

  @override
  final bool temp;

  /// Creates a new [Pod] from the given [value].
  ///
  /// This [Pod] is not automatically disposed of, so it is important to
  /// manually [dispose] of it when it is no longer needed to free up resources.
  PodNotifier(T value) : this._unsafe(value, disposable: true, temp: false);

  /// Creates a new temporary [PodNotifier] from the given [value].
  ///
  /// Temporary Pods are designed to be used with widgets that support them,
  /// such as [PodBuilder] and other builders in the `df_pod` package.
  /// These Pods are automatically disposed of when the associated widget
  /// is removed from the widget tree, ensuring efficient resource management
  /// without manual intervention.
  ///
  /// Use temporary Pods when you want a Pod to have a lifecycle tied to
  /// the widget tree, avoiding the need to manage disposal explicitly.
  PodNotifier.temp(T value) : this._unsafe(value, disposable: true, temp: true);

  /// Creates a new non-disposable/global [PodNotifier] from the given [value].
  ///
  /// These Pods cannot be disposed of, and attempting to do so will throw a
  /// [DoNotDisposePodException].
  ///
  /// Non-disposable Pods should not be used in local scopes. They are intended
  /// to be used as global variables that persist throughout the lifetime of
  /// your app.
  PodNotifier.global(T value)
      : this._unsafe(value, disposable: false, temp: false);

  PodNotifier._unsafe(
    super.value, {
    required this.disposable,
    required this.temp,
  }) : assert(
          temp && disposable == true || !temp,
          'A PodNotifier marked as "temp" must also be marked as "disposable".',
        );

  /// Adds a [listener] to this [PodNotifier] that will be triggered only once.
  /// Once the [listener] is called, it is automatically removed, unlike the
  /// persistent behavior of [addListener].
  ///
  /// This method is useful when you need a callback to execute a single time
  /// in response to a change, ensuring it does not linger in memory or respond
  /// to future changes.
  void addSingleExecutionListener(VoidCallback listener) {
    late final VoidCallback tempListener;
    tempListener = () {
      listener();
      removeListener(tempListener);
    };
    addListener(tempListener);
  }

  /// Dipsoses this [PodNotifier] if [disposable], then sets [isDisposed] to
  /// `true`. Successive calls to this method will be ignored.
  @override
  void dispose() {
    super.maybeDispose(
      super.dispose,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An extension on [PodNotifier] that provides utility methods for
/// down-casting to [Pod] instances.
extension AsPodOnPodNotifierX<T> on PodNotifier<T> {
  /// Attempts to cast this [PodNotifier] to a [Pod] instance. Returns `null`
  /// if the cast is unsuccessful.
  ///
  /// Prefer using [asPod] unless there is a specific need for [asPodOrNull].
  ///
  /// Note: This method is marked as [visibleForTesting] to remind developers
  /// to structure their code in a way that avoids frequent casting,
  /// ensuring clearer and more maintainable code.
  @visibleForTesting
  Pod<T>? asPodOrNull() => letAsOrNull<Pod<T>>(this);

  /// Attempts to cast this [PodListenable] to a [PodNotifier] instance.
  /// Throws a [CannotCastPodException] an if the cast is unsuccessful.
  ///
  /// Note: This method is marked as [visibleForTesting] to remind developers
  /// to structure their code in a way that avoids frequent casting,
  /// ensuring clearer and more maintainable code.
  @visibleForTesting
  Pod<T> asPod() {
    try {
      return this as Pod<T>;
    } catch (_) {
      throw CannotCastPodException();
    }
  }
}
