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
  late Iterable<GenericPod<TParent>> _parents;

  @override
  // ignore: overridden_fields
  late TChild value;

  //
  //
  //

  ChildPod({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
  }) : _reducer = reducer,
       _responder = responder {
    _parents = responder();
    value = reducer(parents.map((p) => p.value).toList());
    _initializeParents(parents);
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
      final newParents = _responder();

      final oldParentsSet = _parents.nonNulls.toSet();
      final newParentsSet = newParents.nonNulls.toSet();
      for (final oldParent in oldParentsSet.difference(newParentsSet)) {
        oldParent._removeChild(this);
      }

      _initializeParents(newParents);
      _parents = newParents;

      final newValue = _reducer(newParents.map((p) => p.value).toList());
      _set(newValue);
    } finally {
      _isDirty = false;
    }
  };

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

typedef TValuesReducerFn<TChild, TParentList> =
    TChild Function(List<TParentList> parentValues);

typedef TPodsResponderFn<T extends Object> = Iterable<GenericPod<T>> Function();
