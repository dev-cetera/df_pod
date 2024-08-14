//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'parts.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class ChildPod<TParent, TChild> extends BindWithMixinPodNotifier<TChild>
    with PodMixin<TChild> {
  //
  //
  //

  final TPodsResponderFn<TParent> _responder;
  final TValuesReducerFn<TChild, TParent> _reducer;

  //
  //
  //

  ChildPod({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
  })  : _reducer = reducer,
        _responder = responder,
        super(
          reducer(responder().map((p) => p?.value).toList()),
        ) {
    _initializeParents();
  }

  //
  //
  //

  ChildPod.temp({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
  })  : _reducer = reducer,
        _responder = responder,
        super.temp(
          reducer(responder().map((p) => p?.value).toList()),
        ) {
    _initializeParents();
  }

  //
  //
  //

  void _initializeParents() {
    final parents = _responder();
    for (var parent in parents) {
      parent?._addChild(this);
      parent?.addListener(_refresh);
    }
  }

  //
  //
  //

  Future<void> _refresh() async {
    final parents = _responder();
    final newValue = _reducer(parents.map((p) => p?.value).toList());
    await _set(newValue);
  }

  //
  //
  //

  @override
  void dispose() {
    final parents = _responder();
    for (var parent in parents) {
      parent?._removeChild(this);
      parent?.removeListener(_refresh);
    }
    super.dispose();
  }
}

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension _AddOrRemoveChildren<T> on PodMixin<T> {
  //
  //
  //

  void _addChild(ChildPod child) {
    if (!child._responder().contains(this)) {
      throw WrongParentPodException();
    }
    if (_children.contains(child)) {
      throw ChildAlreadyAddedPodException();
    }
    addListener(child._refresh);
    _children.add(child);
  }

  //
  //
  //

  void _removeChild(ChildPod child) {
    final didRemove = _children.remove(child);
    if (!didRemove) {
      throw NoRemoveChildPodException();
    }
    removeListener(child._refresh);
  }
}
