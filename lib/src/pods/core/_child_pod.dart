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

final class ChildPod<TParent extends Object, TChild extends Object>
    extends PodNotifier<TChild>
    with GenericPod<TChild>, ProtectedPodMixin<TChild> {
  //
  //
  //

  final TPodsResponderFn<TParent> _responder;
  final TValuesReducerFn<TChild, TParent> _reducer;
  // Stored as a List so the identity short-circuit in [_refresh] can
  // index directly without a List cast. The responder may return any
  // Iterable; we materialise it to a List on every entry.
  late List<GenericPod<TParent>> _parents;

  @override
  // ignore: overridden_fields
  late TChild value;

  //
  //
  //

  ChildPod({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
  })  : _reducer = reducer,
        _responder = responder {
    // Materialise responder output to a List so a `sync*` generator (or
    // any other one-shot iterable) is fully consumed exactly once.
    // [_initializeParents] and the reducer call both iterate; without
    // this snapshot, a generator-style responder would yield nothing on
    // the second walk and parent subscriptions would silently desync.
    final initial = responder().toList();
    _parents = initial;
    value = reducer(initial.map((p) => p.value).toList());
    _initializeParents(initial);
  }

  //
  //
  //

  void _initializeParents(Iterable<GenericPod<TParent>> parents) {
    for (var parent in parents) {
      parent._addChild(this);
    }
  }

  //
  //
  //

  @visibleForTesting
  Iterable<GenericPod<TParent>> get parents => _parents;

  //
  //
  //

  bool _isDirty = false;

  late final VoidCallback _refresh = () {
    // Re-entrance guard: prevent a listener fired during _set below from
    // recursively invoking us within the same call. The body is fully
    // synchronous, so the flag is only ever true while we are mid-refresh.
    // `try/finally` ensures an exception in _responder/_reducer/_set does not
    // leave _isDirty stuck at true (which would silently freeze this child
    // for the rest of its life).
    if (_isDirty) return;
    _isDirty = true;
    try {
      // Materialise to a List so a generator-style responder is consumed
      // exactly once. The diff, the re-subscribe pass, and the reducer
      // call all iterate this list — re-invoking the responder would be
      // racy (different parents could appear in different walks).
      final newParents = _responder().toList();

      // If the parent list is unchanged by element identity, skip the
      // subscription diff and just recompute the value. Common case for
      // `.map()` and arity reducer helpers.
      if (!_parentsIdenticalTo(newParents)) {
        final oldParentsSet = _parents.nonNulls.toSet();
        final newParentsSet = newParents.nonNulls.toSet();
        for (final oldParent in oldParentsSet.difference(newParentsSet)) {
          oldParent._removeChild(this);
        }

        _initializeParents(newParents);
        _parents = newParents;
      }

      final newValue = _reducer(newParents.map((p) => p.value).toList());
      _set(newValue);
    } finally {
      _isDirty = false;
    }
  };

  /// Element-wise identity equality between [_parents] and [newParents].
  /// Returns true when the parent set is unchanged in both content and
  /// order, which is the common case — every `.map()` and arity-reducer
  /// helper returns its captured parents on each fire.
  bool _parentsIdenticalTo(List<GenericPod<TParent>> newParents) {
    final parents = _parents;
    if (parents.length != newParents.length) return false;
    for (var i = 0; i < newParents.length; i++) {
      if (!identical(parents[i], newParents[i])) return false;
    }
    return true;
  }

  //
  //
  //

  @override
  void dispose() {
    for (var parent in _parents) {
      parent._removeChild(this);
    }
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TValuesReducerFn<TChild, TParentList> = TChild Function(
  List<TParentList> parentValues,
);

typedef TPodsResponderFn<T extends Object> = Iterable<GenericPod<T>> Function();
