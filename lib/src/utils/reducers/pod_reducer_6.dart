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

/// A class to handle reducing operations for 6 Pods.
final class PodReducer6 {
  PodReducer6._();

  /// Reduces 6 Pods into a [ChildPod].
  static ChildPod<dynamic, C> reduce<C, P1, P2, P3, P4, P5, P6>(
    TResponderFn6<P1, P2, P3, P4, P5, P6> responder,
    TNullableReducerFn6<C, P1, P2, P3, P4, P5, P6> reducer,
  ) {
    return ChildPod<dynamic, C>(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Reduces 6 Pods into a temporary [ChildPod].
  static ChildPod<dynamic, C> reduceToTemp<C, P1, P2, P3, P4, P5, P6>(
    TResponderFn6<P1, P2, P3, P4, P5, P6> responder,
    TNullableReducerFn6<C, P1, P2, P3, P4, P5, P6> reducer,
  ) {
    return ChildPod<dynamic, C>.temp(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<AnyPod<dynamic>?> _toList<P1, P2, P3, P4, P5, P6>(
    TResponderFn6<P1, P2, P3, P4, P5, P6> responder,
  ) {
    final response = responder.call();
    return [
      response.$1,
      response.$2,
      response.$3,
      response.$4,
      response.$5,
      response.$6,
    ];
  }

  /// Reduces the values from 6 Pods using the provided reducer function.
  static C _reduce<C, P1, P2, P3, P4, P5, P6>(
    TResponderFn6<P1, P2, P3, P4, P5, P6> responder,
    TNullableReducerFn6<C, P1, P2, P3, P4, P5, P6> reducer,
  ) {
    final response = responder();
    return reducer(
      response.$1,
      response.$2,
      response.$3,
      response.$4,
      response.$5,
      response.$6,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn6<P1, P2, P3, P4, P5, P6> = (
  AnyPod<P1>? p1,
  AnyPod<P2>? p2,
  AnyPod<P3>? p3,
  AnyPod<P4>? p4,
  AnyPod<P5>? p5,
  AnyPod<P6>? p6,
)
    Function();

typedef TNullableReducerFn6<C, P1, P2, P3, P4, P5, P6> = C Function(
  AnyPod<P1>? p1,
  AnyPod<P2>? p2,
  AnyPod<P3>? p3,
  AnyPod<P4>? p4,
  AnyPod<P5>? p5,
  AnyPod<P6>? p6,
);

typedef TReducerFn6<C, P1, P2, P3, P4, P5, P6> = C Function(
  AnyPod<P1> p1,
  AnyPod<P2> p2,
  AnyPod<P3> p3,
  AnyPod<P4> p4,
  AnyPod<P5> p5,
  AnyPod<P6> p6,
);
