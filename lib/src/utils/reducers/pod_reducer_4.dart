//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A class to handle reducing operations for 4 Pods.
final class PodReducer4 {
  PodReducer4._();

  /// Reduces 4 Pods into a [ChildPod].
  static ChildPod<dynamic, C> reduce<C, P1, P2, P3, P4>(
    TResponderFn4<P1, P2, P3, P4> responder,
    TNullableReducerFn4<C, P1, P2, P3, P4> reducer,
  ) {
    return ChildPod<dynamic, C>(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Reduces 4 Pods into a temporary [ChildPod].
  static ChildPod<dynamic, C> reduceToTemp<C, P1, P2, P3, P4>(
    TResponderFn4<P1, P2, P3, P4> responder,
    TNullableReducerFn4<C, P1, P2, P3, P4> reducer,
  ) {
    return ChildPod<dynamic, C>.temp(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<PodMixin<dynamic>?> _toList<P1, P2, P3, P4>(
    TResponderFn4<P1, P2, P3, P4> responder,
  ) {
    final response = responder.call();
    return [
      response.$1,
      response.$2,
      response.$3,
      response.$4,
    ];
  }

  /// Reduces the values from 4 Pods using the provided reducer function.
  static C _reduce<C, P1, P2, P3, P4>(
    TResponderFn4<P1, P2, P3, P4> responder,
    TNullableReducerFn4<C, P1, P2, P3, P4> reducer,
  ) {
    final response = responder();
    return reducer(
      response.$1,
      response.$2,
      response.$3,
      response.$4,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn4<P1, P2, P3, P4> = (
  PodMixin<P1>? p1,
  PodMixin<P2>? p2,
  PodMixin<P3>? p3,
  PodMixin<P4>? p4,
)
    Function();

typedef TNullableReducerFn4<C, P1, P2, P3, P4> = C Function(
  PodMixin<P1>? p1,
  PodMixin<P2>? p2,
  PodMixin<P3>? p3,
  PodMixin<P4>? p4,
);

typedef TReducerFn4<C, P1, P2, P3, P4> = C Function(
  PodMixin<P1> p1,
  PodMixin<P2> p2,
  PodMixin<P3> p3,
  PodMixin<P4> p4,
);
