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

abstract base class _ChildPodBase<TParent extends Object, TChild extends Object>
    extends PodNotifier<TChild> with GenericPod<TChild>, ProtectedPodMixin<TChild> {
  //
  //
  //

  final TPodsResponderFn<TParent> _responder;
  final TValuesReducerFn<TChild, TParent> _reducer;
  late Iterable<GenericPod<TParent>?> _parents;

  @override
  // ignore: overridden_fields
  late TChild value;

  //
  //
  //

  _ChildPodBase({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
    required TChild initialValue,
  })  : _reducer = reducer,
        _responder = responder {
    value = initialValue;
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
  Iterable<GenericPod<TParent>?> get parents => _parents;

  //
  //
  //

  bool _isDirty = false;

  late final VoidCallback _refresh = () {
    // Already scheduled for a refresh.
    if (_isDirty) return;
    _isDirty = true;

    // Get the new parents.
    final newParents = _responder();

    // Unsubscribe from any Pods that are no longer parents.
    final oldParentsSet = _parents.nonNulls.toSet();
    final newParentsSet = newParents.nonNulls.toSet();
    for (final oldParent in oldParentsSet.difference(newParentsSet)) {
      oldParent._removeChild(this);
    }

    // Subscribe to new parents.
    _initializeParents(newParents);
    _parents = newParents;

    // Recalculate the value
    final newValue = _reducer(newParents.map((p) => p.value).toList());
    _set(newValue);

    // Reset the flag.
    _isDirty = false;
  };

  //
  //
  //

  @override
  void dispose() {
    for (var parent in _parents) {
      parent?._removeChild(this);
    }
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TValuesReducerFn<TChild, TParentList> = TChild Function(List<TParentList> parentValues);

typedef TPodsResponderFn<T extends Object> = Iterable<GenericPod<T>> Function();
