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

// ignore_for_file: invalid_use_of_visible_for_testing_member

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An alias for [Pod].
typedef Pod<T> = RootPod<T>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A Pod that serves as the root of a Pod parent-child chain.
base class RootPod<T> extends PodNotifier<T> with GenericPod<T> {
  //
  //
  //

  RootPod(
    super.value, {
    super.onBeforeDispose,
  });

  /// Returns the current value of the Pod and calls [refresh]
  T get updateValue {
    this.refresh();
    return value;
  }

  /// Sets the value of the Pod to [newValue] and calls [notifyListeners] if
  /// the value is different from the current value.
  Future<void> set(T newValue) async {
    await super._set(newValue);
  }

  /// Updates the current value of the Pod via [updateValue] and calls
  /// [notifyListeners] if the returned value is different from the current
  /// value.
  Future<void> update(T Function(T oldValue) updateValue) async {
    final newValue = updateValue(value);
    await set(newValue);
  }

  /// Triggers [notifyListeners] after a zero-duration delay.
  Future<void> refresh() async {
    await Future.delayed(Duration.zero, notifyListeners);
  }
}
