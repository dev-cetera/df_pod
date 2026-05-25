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

/// An alias for [GenericPod].
typedef GenericPod<T extends Object> = GenericPodMixin<T>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin for managing [RootPod] and [ChildPod].
mixin GenericPodMixin<T extends Object> on PodNotifier<T>, ValueListenable<T> {
  //
  //
  //

  /// Pending [cond] completers. Errored on [dispose] so a caller that is
  /// `await`-ing a predicate that will never match (because the pod went
  /// away) gets a [Resolvable] error instead of hanging forever. Removed
  /// from the set when the predicate matches normally.
  ///
  /// Lazy-initialised (v0.20.0 P3): pods that never call [cond] never
  /// allocate the backing Set. Saves ~32 bytes per pod in the common
  /// case where cond is unused.
  Set<SafeCompleter<T>>? _pendingConds;

  /// Returns the value of the Pod when the [test] returns `true`.
  ///
  /// The internal listener is held strongly via [pinListener] so dropping
  /// the returned [Resolvable] without awaiting it cannot cause the
  /// listener to be garbage collected before [test] succeeds.
  ///
  /// Failure modes — all surface as `Err` on the returned [Resolvable]
  /// rather than crashing the caller or hanging forever:
  /// - **Pod disposed before [test] ever matches** → `Err(StateError(...))`
  ///   ("Pod disposed before cond predicate became true").
  /// - **[test] throws** (sync first call or any later notify) →
  ///   `Err(thrown error)`. Previously a throwing predicate left the
  ///   [SafeCompleter] permanently pending and a throwing initial sync
  ///   check propagated out of [cond] itself, depending on timing.
  Resolvable<T> cond(bool Function(T value) test) {
    final finisher = SafeCompleter<T>();
    late final VoidCallback check;
    check = () {
      // Defensive try/catch: a throwing predicate must NOT leave the
      // completer stuck pending. Convert any throw into an Err on the
      // returned Resolvable so awaiting code can react.
      try {
        if (test(value)) {
          finisher.complete(value).end();
          _pendingConds?.remove(finisher);
          unpinListener(check);
          removeListener(check);
        }
      } catch (e, s) {
        finisher.resolve(Sync.err(Err(e, stackTrace: s))).end();
        _pendingConds?.remove(finisher);
        unpinListener(check);
        removeListener(check);
      }
    };
    check();
    // Whether the initial sync check resolved with Ok or Err, return the
    // finisher's resolvable so the caller's await observes the actual
    // result.
    if (finisher.isCompleted) {
      return finisher.resolvable();
    } else {
      (_pendingConds ??= <SafeCompleter<T>>{}).add(finisher);
      pinListener(check);
      addStrongRefListener(strongRefListener: check);
      return finisher.resolvable();
    }
  }

  /// Children of this pod. Stored as [WeakReference]s so a derived
  /// [ChildPod] that the caller forgot to retain can be garbage collected
  /// instead of being pinned for the lifetime of this pod. Live entries
  /// are still walked and disposed in [disposeChildren]; dead entries are
  /// skipped (and pruned). Callers that want explicit ownership should
  /// store the child in a field as usual.
  final _children = <WeakReference<ChildPod<Object, Object>>>[];

  void _addChild(ChildPod<Object, Object> child) {
    for (final ref in _children) {
      if (identical(ref.target, child)) return;
    }
    // Intentionally NOT guarded with `isDisposed` — the assert in
    // [addStrongRefListener] is the canonical signal that the caller is
    // operating on a disposed pod and must be allowed to fire so
    // `.map()` / `.reduce()` on a disposed parent fails loudly in debug.
    // ignore: invalid_use_of_visible_for_testing_member
    addStrongRefListener(strongRefListener: child._refresh);
    _children.add(WeakReference(child));
  }

  void _removeChild(ChildPod<Object, Object> child) {
    var didRemove = false;
    _children.removeWhere((ref) {
      final t = ref.target;
      if (t == null) return true;
      if (identical(t, child)) {
        didRemove = true;
        return true;
      }
      return false;
    });
    if (didRemove) {
      removeListener(child._refresh);
    }
  }

  /// Tracks whether a deferred notify has been scheduled but not yet
  /// fired. v0.20.0 (P2) coalesces multiple back-to-back
  /// `set(.., notifyImmediately: false)` calls into a single notify —
  /// pre-coalescing, N rapid sets scheduled N post-frame callbacks and
  /// every listener was invoked N times in the same frame (each call
  /// seeing the same final [value]). Listeners now get exactly one
  /// notification per frame regardless of how many writes happen.
  bool _hasPendingDeferredNotify = false;

  bool _set(T newValue, {bool notifyImmediately = true}) {
    // Short-circuit on disposed pods. Earlier revisions mutated [value]
    // and only the (debug-only) assert in [notifyListeners] flagged the
    // misuse — in release builds, [value] was silently overwritten on a
    // dead pod, leaving readers with a freshly-mutated field on an object
    // that no longer notifies. For medical-grade callers this is the most
    // dangerous failure mode: the data looks live but the world has moved
    // on.
    if (isDisposed) return false;
    if (!isDefinitelyComparableOrEquatable(newValue) ||
        _safeNotEquals(newValue)) {
      value = newValue;
      if (notifyImmediately) {
        notifyListeners();
      } else {
        _scheduleDeferredNotify();
      }
      return true;
    }
    return false;
  }

  /// Schedules a single deferred [notifyListeners] for the next frame /
  /// microtask. Repeated calls within the same coalescing window are
  /// no-ops (the already-scheduled callback will see the latest
  /// [value]).
  ///
  /// [WidgetsBinding.instance] throws if no binding is initialized
  /// (background isolate, dart-only test, server-side use); we fall
  /// back to a microtask so non-Flutter callers do not break.
  void _scheduleDeferredNotify() {
    if (_hasPendingDeferredNotify) return;
    _hasPendingDeferredNotify = true;
    void fire() {
      _hasPendingDeferredNotify = false;
      if (!isDisposed) notifyListeners();
    }

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) => fire());
    } catch (_) {
      scheduleMicrotask(fire);
    }
  }

  /// Compares [newValue] against the current [value] via `!=` with a
  /// defensive try/catch. A custom `operator ==` that throws would
  /// otherwise propagate out of [set] / [update], leaving the pod in an
  /// unknown state — for medical-grade we treat a throwing equality as
  /// "definitely changed" (over-notify is safer than missing a notify).
  bool _safeNotEquals(T newValue) {
    try {
      return newValue != value;
    } catch (_) {
      return true;
    }
  }

  /// Reduces the current Pod and [other] into a single [ChildPod].
  ChildPod<Object, C> reduce<C extends Object, O extends Object>(
    GenericPod<O> other,
    TReducerFn2<C, T, O> reducer,
  ) {
    return PodReducer2.reduce<C, T, O>(
      () => (this, other),
      (a, b) => reducer(a, b),
    );
  }

  /// Maps `this` [GenericPod] to a new [ChildPod] using the specified [reducer].
  ChildPod<T, B> map<B extends Object>(B Function(T value) reducer) {
    return ChildPod<T, B>(
      responder: () => [this],
      reducer: (_) => reducer(value),
    );
  }

  /// Disposes all children before disposing `this`.
  ///
  /// Wrapped in try/finally so a child whose [dispose] throws still lets
  /// [super.dispose] run — otherwise the pod was left half-disposed
  /// (`isDisposed == false`, `_listeners` still attached) and subsequent
  /// `set` calls kept firing listeners.
  @override
  void dispose() {
    try {
      disposeChildren();
    } finally {
      _failPendingConds();
      super.dispose();
    }
  }

  /// Errors every pending [cond] so callers awaiting one get a clean
  /// failure rather than a hang. Called from [dispose] before the
  /// underlying [SafeCompleter]'s pin set is cleared by
  /// [WeakChangeNotifier.dispose].
  void _failPendingConds() {
    final pc = _pendingConds;
    if (pc == null || pc.isEmpty) return;
    final snapshot = pc.toList();
    pc.clear();
    _pendingConds = null;
    for (final c in snapshot) {
      if (c.isCompleted) continue;
      c
          .resolve(
            Sync.err(
              Err(
                StateError(
                  'Pod disposed before cond predicate became true',
                ),
              ),
            ),
          )
          .end();
    }
  }

  /// Disposes and removes all children.
  ///
  /// Iterates a snapshot of currently-live children. Dead [WeakReference]s
  /// (children that were GC'd because no one held them) are skipped and
  /// will be pruned on the next mutation of [_children]. [ChildPod.dispose]
  /// already walks `_parents` and calls `parent._removeChild(this)`, which
  /// mutates [_children] from underneath us — that's why we iterate a
  /// snapshot. Calling `_removeChild` again here would be a no-op (the
  /// child has already been pulled from the set and its listener removed),
  /// so the loop body just disposes.
  @protected
  void disposeChildren() {
    final live = <ChildPod<Object, Object>>[];
    for (final ref in _children) {
      final t = ref.target;
      if (t != null) live.add(t);
    }
    for (final child in live) {
      try {
        child.dispose();
      } catch (e) {
        Log.err(e, tags: {#df_pod});
      }
    }
  }
}
