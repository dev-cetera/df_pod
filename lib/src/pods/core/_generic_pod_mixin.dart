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
  /// Lazy-initialised: pods that never call [cond] never allocate the
  /// backing Set.
  Set<SafeCompleter<T>>? _pendingConds;

  /// Returns the value of the Pod when the [test] returns `true`.
  ///
  /// The internal listener is held strongly via [pinListener] so dropping
  /// the returned [Resolvable] without awaiting it cannot cause the
  /// listener to be garbage collected before [test] succeeds.
  ///
  /// Failure modes — all surface as `Err` on the returned [Resolvable]
  /// rather than crashing the caller or hanging forever:
  /// - **Pod disposed before [test] ever matches** → `Err(StateError(...))`.
  /// - **[test] throws** (sync first call or any later notify) →
  ///   `Err(thrown error)`.
  Resolvable<T> cond(bool Function(T value) test) {
    // Bail out on a disposed pod: addStrongRefListener is a release-mode
    // no-op on a disposed notifier, so subscribing would mean the
    // SafeCompleter never resolves and the caller's await hangs.
    if (isDisposed) {
      return Sync.err(
        Err(StateError('Cannot call cond() on a disposed pod')),
      );
    }
    final finisher = SafeCompleter<T>();
    late final VoidCallback check;
    check = () {
      // A throwing predicate must not leave the completer stuck — convert
      // throws into an Err on the returned Resolvable.
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
    if (finisher.isCompleted) {
      return finisher.resolvable();
    }
    // A side-effecting predicate may have disposed the pod during the
    // sync check above. Without this guard, subscribing would be a no-op
    // and the finisher would never resolve.
    if (isDisposed) {
      finisher
          .resolve(
            Sync.err(
              Err(
                StateError(
                  'Pod was disposed during cond() predicate execution',
                ),
              ),
            ),
          )
          .end();
      return finisher.resolvable();
    }
    (_pendingConds ??= <SafeCompleter<T>>{}).add(finisher);
    pinListener(check);
    addStrongRefListener(strongRefListener: check);
    return finisher.resolvable();
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
  /// fired. Multiple `set(.., notifyImmediately: false)` calls within a
  /// frame coalesce into a single notify that sees the latest [value].
  bool _hasPendingDeferredNotify = false;

  bool _set(T newValue, {bool notifyImmediately = true}) {
    // Disposed pods must not mutate [value] — readers would otherwise
    // see a freshly-overwritten field on a notifier that no longer fires.
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
  /// defensive try/catch. A throwing custom `operator ==` would otherwise
  /// propagate out of [set] / [update]; we treat a throwing equality as
  /// "definitely changed" — over-notify is safer than missing a notify.
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

  /// Disposes all children, fails pending cond completers, then
  /// disposes `this`.
  ///
  /// Each step is independently guarded so a throw in one cannot
  /// prevent the others from running — [super.dispose] in particular
  /// MUST run, or the pod is left half-disposed (`_listeners` still
  /// attached) and subsequent `set` calls would keep firing.
  @override
  void dispose() {
    try {
      disposeChildren();
    } catch (e) {
      Log.err(e, tags: {#df_pod});
    }
    try {
      _failPendingConds();
    } catch (e) {
      Log.err(e, tags: {#df_pod});
    }
    super.dispose();
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
  /// are skipped and pruned lazily. We must iterate a snapshot because
  /// [ChildPod.dispose] calls back into `parent._removeChild(this)` and
  /// mutates [_children] from underneath us.
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
