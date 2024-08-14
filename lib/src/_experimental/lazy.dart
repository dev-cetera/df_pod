//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A class representing a lazily-initialized value of type [T].
class Lazy<T> {
  //
  //
  //

  final _pIsInitialized = Pod<bool>(false);
  late T _value;

  //
  //
  //

  Lazy([T? initialValue]) {
    if (initialValue != null) {
      this.value = initialValue;
    }
  }

  //
  //
  //

  /// Returns `true` if the value has been initialized, `false` otherwise.
  bool get isInitialized => this._pIsInitialized.value;

  /// Returns the value of the [Lazy] instance. Throws an error if the value
  /// has not been initialized yet.
  T get value => this._value;

  /// Returns the value of the [Lazy] instance if it has been initialized,
  /// `null` otherwise.
  ///
  /// Note the obvious issue if T is of type `Null`.
  T? get tryValue => this.isInitialized ? this._value : null;

  /// Sets the value of the [Lazy] instance to [newValue].
  set value(T newValue) => this
    .._pIsInitialized.set(true)
    .._value = newValue;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An extension on all types [T] that adds a `lazy` getter, allowing for easy
/// construction of [Lazy<T>] instances.
extension LazyX<T> on T {
  Lazy<T> get lazy => Lazy<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An extension on [Lazy<T>] instances that adds a `wait` getter, allowing for
/// asynchronous waiting until the value is initialized.
extension LazyWaiterX<T> on Lazy<T> {
  /// Returns a [Future] that resolves with a tuple containing a [bool]
  /// indicating whether the value has been initialized, and the current value
  /// of the [Lazy<T>] instance.
  Future<(bool, T)> get wait async {
    final completer = Completer<bool>();
    _pIsInitialized.addSingleExecutionListener(() async {
      if (!completer.isCompleted) {
        completer.complete(_pIsInitialized.value);
      }
    });

    final isInitialized = await completer.future;
    return (isInitialized, _value);
  }
}
