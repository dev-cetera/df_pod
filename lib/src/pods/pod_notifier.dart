//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/widgets.dart';

import 'pod_disposable_mixin.dart';

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

  PodNotifier(
    super.value, {
    this.disposable = true,
    this.temp = false,
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
