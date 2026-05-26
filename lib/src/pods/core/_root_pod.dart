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

  /// Creates a [RootPod] whose value tracks [stream]. Errors emitted by
  /// the stream are passed to [onError]; if [onError] is not supplied
  /// they are logged via `df_log`. The subscription is cancelled on
  /// [dispose].
  ///
  /// In-flight events that arrive after [dispose] (before the async
  /// [StreamSubscription.cancel] propagates) are dropped.
  ///
  /// `onAfterDispose` is wired *before* [stream.listen] runs so a
  /// synchronous emit on subscribe cannot leak the subscription if a
  /// callback disposes the pod in the same microtask.
  RootPod.fromStream(
    Stream<T> stream, {
    required T initialValue,
    void Function(Object error, StackTrace stack)? onError,
  }) : value = initialValue {
    StreamSubscription<T>? subscription;
    onAfterDispose = () {
      final s = subscription;
      if (s == null) return;
      // A throw from cancel — uncommon, usually a misbehaving stream
      // transformer — should surface in the log, not be swallowed.
      s.cancel().catchError((Object e, StackTrace st) {
        Log.err(e, tags: {#df_pod});
      });
    };
    subscription = stream.listen(
      (v) {
        if (isDisposed) return;
        _set(v);
      },
      onError: (Object error, StackTrace stack) {
        if (isDisposed) return;
        if (onError != null) {
          onError(error, stack);
        } else {
          Log.err(error, tags: {#df_pod});
        }
      },
    );
    // If a synchronous emit during `listen` already disposed us,
    // `onAfterDispose` ran against a still-null `subscription`. Cancel
    // the now-assigned subscription explicitly so it doesn't outlive
    // the pod.
    if (isDisposed) {
      subscription.cancel().catchError((Object e, StackTrace st) {
        Log.err(e, tags: {#df_pod});
      });
    }
  }

  /// Returns the current value of the Pod and calls [refresh].
  ///
  /// Note: the value returned is the *current* value, not the
  /// post-refresh value. [refresh] schedules an async notify; the read
  /// happens synchronously. Callers that need the post-refresh value
  /// should `await pod.refresh(); read pod.value;`.
  T get updateValue {
    refresh();
    return value;
  }

  /// Sets the value of the Pod to [newValue] and calls [notifyListeners]
  /// if the value is different from the current value.
  ///
  /// No-op on a disposed pod (the value field is *not* mutated).
  void set(T newValue, {bool notifyImmediately = true}) {
    _set(newValue, notifyImmediately: notifyImmediately);
  }

  /// Updates the current value of the Pod via [updateValue] and calls
  /// [notifyListeners] if the returned value is different from the current
  /// value.
  ///
  /// No-op on a disposed pod (see [set]).
  void update(
    T Function(T oldValue) updateValue, {
    bool notifyImmediately = true,
  }) {
    if (isDisposed) return;
    final newValue = updateValue(value);
    _set(newValue, notifyImmediately: notifyImmediately);
  }

  /// Triggers [notifyListeners] after a zero-duration delay. Returns a
  /// [Future] that completes once the notify has been scheduled and
  /// (potentially) fired — callers that need to read post-notify state
  /// can `await` it.
  ///
  /// Safe to call right before [dispose]; the scheduled tick is a no-op
  /// once [isDisposed] flips true.
  Future<void> refresh() {
    return Future.delayed(Duration.zero, () {
      if (!isDisposed) notifyListeners();
    });
  }
}
