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

final class ChildPod<TParent, TChild> extends PodNotifier<TChild>
    with AnyPod<TChild> {
  //
  //
  //

  final TPodsResponderFn<TParent> _responder;
  final TValuesReducerFn<TChild, TParent> _reducer;

  //
  //
  //

  factory ChildPod({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
  }) {
    final parents = responder();
    final initialValue = reducer(parents.map((p) => p?.value).toList());
    final temp = ChildPod._(
      responder: responder,
      reducer: reducer,
      initialValue: initialValue,
    );
    temp._initializeParents(parents);
    return temp;
  }

  ChildPod._({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
    required TChild initialValue,
  })  : _reducer = reducer,
        _responder = responder,
        super(initialValue);

  //
  //
  //

  factory ChildPod.temp({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
  }) {
    final parents = responder();
    final initialValue = reducer(parents.map((p) => p?.value).toList());
    final temp = ChildPod._temp(
      responder: responder,
      reducer: reducer,
      initialValue: initialValue,
    );
    temp._initializeParents(parents);
    return temp;
  }

  ChildPod._temp({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
    required TChild initialValue,
  })  : _reducer = reducer,
        _responder = responder,
        super.temp(initialValue);

  //
  //
  //

  void _initializeParents(Iterable<AnyPod<TParent>?> parents) {
    for (var parent in parents) {
      parent?._addChild(this);
    }
  }

  //
  //
  //

  Future<void> _refresh() async {
    final parents = _responder();
    _initializeParents(parents);
    final newValue = _reducer(parents.map((p) => p?.value).toList());
    await _set(newValue);
  }

  //
  //
  //

  /// [ChildPod] should not be disposed of directy. These Pods are automatically
  /// disposed of when their parent is disposed.
  @protected
  @override
  void dispose() {
    final parents = _responder();
    for (var parent in parents) {
      parent?._removeChild(this);
    }
    super.dispose();
  }
}
