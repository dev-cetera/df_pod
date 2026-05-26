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

  /// Identity-keyed Set so the per-refresh diff in [_getValue] can do
  /// O(1) "is this already subscribed?" lookups without allocating a
  /// temporary `oldSet`. Iteration order doesn't matter for any consumer.
  final _listenables = Set<ValueListenable<Object>>.identity();

  //
  //
  //

  /// Refreshes the cached value and reconciles parent subscriptions.
  ///
  /// Diffs subscriptions rather than remove-all-then-add-all, so a
  /// ReducerPod watching N stable parents avoids 2·N listener-list
  /// mutations per parent fire. The "is this still wanted?" check
  /// adaptively uses a linear identity scan (small N — the common
  /// case, 2-3 parents) or a one-shot Set conversion (large N).
  ///
  /// Duplicate listenables in the responder output collapse to a
  /// single subscription (matches [ChildPod]'s `_addChild` dedup).
  Option<T> _getValue() {
    final refresh = _refresh!;
    final values = responder().toList();
    final newListenables = <ValueListenable<Object>>[];
    for (final option in values) {
      if (option.isNone()) continue;
      UNSAFE:
      newListenables.add(option.unwrap());
    }

    // Below the threshold, a linear identical() scan is faster and
    // allocation-free; above it, the Set conversion pays off.
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

    // Run the reducer before committing subscription changes. If the
    // reducer throws or triggers dispose, no rollback is needed and a
    // newly-joined parent cannot end up subscribed to a dead pod.
    // Parents that "leave" stay subscribed for the duration of the
    // reducer call — the [_isDirty] guard prevents re-entrant refreshes
    // if they fire mid-reducer.
    final valuesToReduce = values.map((e) => e.map((e) => e.value)).toList();
    final result = reducer(valuesToReduce);

    // If the reducer (or a callback it triggered) disposed us, abandon
    // the subscription update. Re-attaching would leave listeners
    // referencing a now-null `_refresh` that NPEs on the next fire.
    if (isDisposed) return result;

    for (final l in toRemove) {
      _detachListener(l, refresh);
    }
    for (final l in toAdd) {
      _attachListener(l, refresh);
    }
    _listenables
      ..removeAll(toRemove)
      ..addAll(toAdd);
    return result;
  }

  /// Subscribes [refresh] to [l] using the API appropriate for the
  /// listenable's actual type. For `WeakChangeNotifier`-based pods we
  /// route through `addStrongRefListener` (enforced by
  /// `mustBeStrongRefOrError`); for stock `ValueNotifier` /
  /// `ChangeNotifier` we fall back to `addListener`.
  static void _attachListener(
    ValueListenable<Object> l,
    VoidCallback refresh,
  ) {
    if (l is WeakChangeNotifier) {
      // Explicit cast: `ValueListenable<Object>` and `WeakChangeNotifier`
      // have no subtype relationship, so Dart's `is` check can't
      // intersect-promote `l`.
      (l as WeakChangeNotifier)
          .addStrongRefListener(strongRefListener: refresh);
    } else {
      l.addListener(refresh);
    }
  }

  /// Inverse of [_attachListener]. Kept as a named helper for symmetry.
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
