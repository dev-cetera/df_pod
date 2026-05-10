//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
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

  /// Creates a [RootPod] whose value tracks [stream]. Errors emitted by the
  /// stream are passed to [onError]; if [onError] is not supplied they are
  /// logged via `df_log` so they do not propagate to the zone's uncaught
  /// handler. The subscription is cancelled on [dispose].
  RootPod.fromStream(
    Stream<T> stream, {
    required T initialValue,
    void Function(Object error, StackTrace stack)? onError,
  }) : value = initialValue {
    final subscription = stream.listen(
      _set,
      onError: onError ??
          (Object error, StackTrace stack) {
            Log.err(error, {#df_pod});
          },
    );
    onAfterDispose = () {
      unawaited(subscription.cancel());
    };
  }

  /// Returns the current value of the Pod and calls [refresh]
  T get updateValue {
    refresh();
    return value;
  }

  /// Sets the value of the Pod to [newValue] and calls [notifyListeners] if
  /// the value is different from the current value.
  void set(T newValue, {bool notifyImmediately = true}) {
    _set(newValue, notifyImmediately: notifyImmediately);
  }

  /// Updates the current value of the Pod via [updateValue] and calls
  /// [notifyListeners] if the returned value is different from the current
  /// value.
  void update(
    T Function(T oldValue) updateValue, {
    bool notifyImmediately = true,
  }) {
    final newValue = updateValue(value);
    _set(newValue, notifyImmediately: notifyImmediately);
  }

  /// Triggers [notifyListeners] after a zero-duration delay.
  ///
  /// Safe to call right before [dispose]; the scheduled tick is a no-op once
  /// [isDisposed] flips true.
  void refresh() {
    Future.delayed(Duration.zero, () {
      if (!isDisposed) notifyListeners();
    });
  }
}
