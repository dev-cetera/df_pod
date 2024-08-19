//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A Pod that derives its value from parent Pods using a specified reducer
/// function, updating when any of its parent Pods change.
final class ChildPod<TParent, TChild> extends _ChildPodBase<TParent, TChild>
    with ProtectedPodMixin {
  //
  //
  //

  factory ChildPod._({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
    TOnBeforeDispose<TChild>? onBeforeDispose,
  }) {
    final parents = responder();
    final initialValue = reducer(parents.map((p) => p?.value).toList());
    final temp = ChildPod._internal(
      responder: responder,
      reducer: reducer,
      initialValue: initialValue,
      onBeforeDispose: onBeforeDispose,
    );
    temp._initializeParents(parents);
    return temp;
  }

  //
  //
  //

  ChildPod._internal({
    required super.responder,
    required super.reducer,
    required super.initialValue,
    super.onBeforeDispose,
  }) : super();
}
