//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An alias for [Pod].
typedef Pod<T extends Object> = RootPod<T>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A Pod that serves as the root of a Pod parent-child chain.
base class RootPod<T extends Object> extends PodNotifier<T> with GenericPod<T> {
  //
  //
  //

  @override
  @protected
  // ignore: overridden_fields
  T value;

  RootPod(this.value);

  /// Returns the current value of the Pod and calls [refresh]
  T get updateValue {
    this.refresh();
    return value;
  }

  /// Sets the value of the Pod to [newValue] and calls [notifyListeners] if
  /// the value is different from the current value.
  void set(
    T newValue, {
    bool notifyImmediately = true,
  }) {
    _set(
      newValue,
      notifyImmediately: notifyImmediately,
    );
  }

  /// Updates the current value of the Pod via [updateValue] and calls
  /// [notifyListeners] if the returned value is different from the current
  /// value.
  void update(
    T Function(T oldValue) updateValue, {
    bool notifyImmediately = true,
  }) {
    final newValue = updateValue(value);
    _set(
      newValue,
      notifyImmediately: notifyImmediately,
    );
  }

  /// Triggers [notifyListeners] after a zero-duration delay.
  void refresh() {
    Future.delayed(Duration.zero, notifyListeners);
  }
}
