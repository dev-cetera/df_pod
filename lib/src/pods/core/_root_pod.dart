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
  ///
  /// In-flight events that arrive after [dispose] (the async [StreamSubscription.cancel]
  /// hasn't propagated yet) are dropped instead of hitting the disposed-pod
  /// assertion in [WeakChangeNotifier.notifyListeners].
  ///
  /// Implementation note: `onAfterDispose` is wired up *before* [stream.listen]
  /// is called so a synchronous emit during listen (e.g. a behaviour-subject
  /// stream that drains on subscribe) cannot leak the subscription if a
  /// callback in the same microtask disposes the pod. The subscription field
  /// is nullable to bridge the gap between wiring up the handler and the
  /// `listen` call returning.
  RootPod.fromStream(
    Stream<T> stream, {
    required T initialValue,
    void Function(Object error, StackTrace stack)? onError,
  }) : value = initialValue {
    StreamSubscription<T>? subscription;
    onAfterDispose = () {
      final s = subscription;
      if (s != null) unawaited(s.cancel());
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

  /// Sets the value of the Pod to [newValue] and calls [notifyListeners] if
  /// the value is different from the current value.
  ///
  /// No-op on a disposed pod (the value field is *not* mutated). This is a
  /// behavior change from the silent-mutate semantics in earlier revisions,
  /// where the value field was overwritten and only the debug-only assert
  /// in [notifyListeners] flagged the misuse.
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
