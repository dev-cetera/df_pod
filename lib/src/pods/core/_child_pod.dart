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

/// A Pod that derives its value from parent Pods using a specified reducer
/// function, updating when any of its parent Pods change.
final class ChildPod<TParent extends Object, TChild extends Object>
    extends _ChildPodBase<TParent, TChild> with ProtectedPodMixin {
  //
  //
  //

  factory ChildPod._({
    required TPodsResponderFn<TParent> responder,
    required TValuesReducerFn<TChild, TParent> reducer,
  }) {
    final parents = responder();
    final initialValue = reducer(parents.map((p) => p.value).toList());
    final temp = ChildPod._internal(
      responder: responder,
      reducer: reducer,
      initialValue: initialValue,
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
  }) : super();
}
