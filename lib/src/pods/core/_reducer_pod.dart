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

/// A Pod that listens to changes to existing Pods returned by the [responder].
/// When any of these returned Pods update, it recalculates its value using the
/// [reducer] function, then calls the [responder] again to refresh Pods to
/// listen to. This recursive behaviour ensures that the Pod continuously
/// listens to new changes from any updated Pods.
///
/// [T] is the type of this Pod and the value produced by the [reducer]
/// function.
///
/// Note that when this pod disposes via [dispose], it will not dispose the Pods
/// provided by [responder]. Explicit disposal is needed.
base class ReducerPod<T extends Object> extends PodNotifier<T>
    with GenericPod<T> {
  //
  //
  //

  /// Produces a list of Pods to listen to. This gets called recursively each
  /// time any of the Pods in the returned list change.
  final Iterable<Option<ValueListenable<Object>>> Function() responder;

  /// Reduces the values of the current Pods returned by [responder] to a
  /// single value of type [T], to update this Pod's [value].
  final Option<T> Function(List<Option> values) reducer;

  //
  //
  //

  factory ReducerPod.single(Option<ValueListenable<T>> Function() responder) {
    return ReducerPod(
      responder: () => [responder()],
      reducer: (values) {
        UNSAFE:
        return values.first.transf<T>().unwrap();
      },
    );
  }

  //
  //
  //

  @override
  // ignore: overridden_fields
  late T value;

  ReducerPod({required this.responder, required this.reducer}) {
    // First-pass: subscribe to parents AND compute the initial value, then
    // initialize `value` directly. Going through `_set` here would crash on a
    // [LateInitializationError] for any [Comparable]/[num]/[bool]/[Enum] T,
    // because `_set`'s equality short-circuit reads `value` before it has been
    // assigned. Subsequent fires go through `_refresh` -> `_set` normally.
    final initial = _getValue();
    if (initial.isSome()) {
      UNSAFE:
      value = initial.unwrap();
    }
  }

  //
  //
  //

  bool _isDirty = false;

  late VoidCallback? _refresh = () {
    // Re-entrance guard: a listener fired during `_set` below could cascade
    // back into us. The body is fully synchronous, so the flag is only ever
    // true while we are mid-refresh. Mirrors the guard in `ChildPod._refresh`.
    if (_isDirty) return;
    _isDirty = true;
    try {
      final option = _getValue();
      if (option.isSome()) {
        UNSAFE:
        _set(option.unwrap());
      }
    } finally {
      _isDirty = false;
    }
  };

  //
  //
  //

  /// Stored as an identity-keyed Set (v0.20.0 P1) so the per-refresh
  /// diff in [_getValue] can do O(1) "is this already subscribed?"
  /// lookups instead of allocating a temporary `oldSet` every call.
  /// Iteration order doesn't matter for any consumer.
  final _listenables = Set<ValueListenable<Object>>.identity();

  //
  //
  //

  /// Refreshes the cached value and reconciles parent subscriptions.
  ///
  /// v0.20.0 (O1): Diffs subscriptions instead of remove-all-then-add-all.
  /// For a [ReducerPod] watching N stable parents that update at high
  /// frequency, this avoids 2·N listener-list mutations per parent fire.
  /// On reducer throw, subscriptions roll back so the pod remains
  /// consistent with [_listenables] (the old code left the pod with
  /// zero subscriptions on throw, silently freezing it).
  ///
  /// v0.20.0 (P1 + P5): [_listenables] is now an identity-Set so the
  /// per-refresh "is this already subscribed?" check is O(1) without
  /// allocating an `oldSet` copy. The "is this still wanted?" check
  /// against [newListenables] adaptively uses either a linear identity
  /// scan (small) or a one-shot Set conversion (large) — the small
  /// case is the common one for ReducerPod (typically 2-3 parents) and
  /// linear is faster than a hashed lookup at that size.
  ///
  /// Duplicate listenables in the responder output collapse to a single
  /// subscription (matches [ChildPod]'s `_addChild` dedup behaviour).
  Option<T> _getValue() {
    final refresh = _refresh!;
    final values = responder().toList();
    final newListenables = <ValueListenable<Object>>[];
    for (final option in values) {
      if (option.isNone()) continue;
      UNSAFE:
      newListenables.add(option.unwrap());
    }

    // Threshold tuned for the typical case: ReducerPods almost always
    // watch 2-7 parents. Below the threshold, the linear identical()
    // scan is faster (and zero-allocation); above it, the Set conversion
    // pays off because the inner `contains` becomes O(1).
    const smallThreshold = 8;
    final useSetForNew = newListenables.length > smallThreshold;
    final newSet = useSetForNew
        ? (Set<ValueListenable<Object>>.identity()..addAll(newListenables))
        : null;

    bool stillNeeded(ValueListenable<Object> l) {
      if (newSet != null) return newSet.contains(l);
      for (final fresh in newListenables) {
        if (identical(l, fresh)) return true;
      }
      return false;
    }

    final toRemove = <ValueListenable<Object>>[];
    for (final old in _listenables) {
      if (!stillNeeded(old)) toRemove.add(old);
    }

    final toAdd = <ValueListenable<Object>>[];
    for (final fresh in newListenables) {
      if (_listenables.contains(fresh)) continue;
      // Dedup against already-collected adds (handles
      // `[parent, parent]`-style duplicates from the responder).
      var dup = false;
      for (final ad in toAdd) {
        if (identical(ad, fresh)) {
          dup = true;
          break;
        }
      }
      if (!dup) toAdd.add(fresh);
    }

    for (final l in toRemove) {
      _detachListener(l, refresh);
    }
    for (final l in toAdd) {
      _attachListener(l, refresh);
    }

    try {
      final valuesToReduce = values.map((e) => e.map((e) => e.value)).toList();
      final result = reducer(valuesToReduce);
      // Commit the dedup'd new subscription set.
      _listenables
        ..removeAll(toRemove)
        ..addAll(toAdd);
      return result;
    } catch (e) {
      // Roll back so the pod's subscription state matches what was in
      // effect before this call. The old implementation cleared every
      // subscription on throw, leaving the pod silently dead until
      // disposed.
      for (final l in toAdd) {
        _detachListener(l, refresh);
      }
      for (final l in toRemove) {
        _attachListener(l, refresh);
      }
      rethrow;
    }
  }

  /// Subscribes [refresh] to [l] using the API appropriate for the
  /// listenable's actual type. For `WeakChangeNotifier`-based pods we
  /// route through `addStrongRefListener` (the canonical path that the
  /// `mustBeStrongRefOrError` lint enforces); for stock
  /// `ValueNotifier` / `ChangeNotifier` we fall back to the plain
  /// `addListener`. This mirrors `PodCollectionBuilder._attach`.
  ///
  /// Promotion-via-local: Dart's flow analysis does not promote the
  /// parameter `l` directly to `WeakChangeNotifier` (the declared
  /// type `ValueListenable<Object>` has no subtype relationship to
  /// `WeakChangeNotifier`). Assigning to a local then testing lets the
  /// analyzer promote.
  static void _attachListener(
    ValueListenable<Object> l,
    VoidCallback refresh,
  ) {
    if (l is WeakChangeNotifier) {
      // Explicit cast: Dart cannot intersect-promote `l` to both
      // `ValueListenable<Object>` and `WeakChangeNotifier` even after
      // the `is` check (the two types have no subtype relationship).
      // We know it's safe because of the just-passed type test.
      (l as WeakChangeNotifier)
          .addStrongRefListener(strongRefListener: refresh);
    } else {
      l.addListener(refresh);
    }
  }

  /// Inverse of [_attachListener]. `removeListener` exists on the
  /// `Listenable` interface for both code paths, so a single call
  /// suffices — but we keep it as a named helper for symmetry and to
  /// localise the future change if WeakChangeNotifier ever grows a
  /// distinct removal entry point.
  static void _detachListener(
    ValueListenable<Object> l,
    VoidCallback refresh,
  ) {
    l.removeListener(refresh);
  }

  //
  //
  //

  @override
  void dispose() {
    final refresh = _refresh;
    _refresh = null;
    if (refresh != null) {
      for (final listenable in _listenables) {
        _detachListener(listenable, refresh);
      }
    }
    super.dispose();
  }
}
