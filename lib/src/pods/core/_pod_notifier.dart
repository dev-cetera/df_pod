//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An enhanced alternative to [ValueNotifier] that provides additional
/// lifecycle management capabilities through the [PodDisposable].
abstract class PodNotifier<T> extends PodDisposable<T> {
  //
  //
  //

  T _value;

  @override
  T get value => _value;

  /// Creates a new [Pod] from the given [value]. Calls [onBeforeDispose]
  /// immediately before disposing.
  PodNotifier(
    this._value, {
    super.onBeforeDispose,
  });

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
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TOnBeforeDispose<T> = void Function(T value)?;
