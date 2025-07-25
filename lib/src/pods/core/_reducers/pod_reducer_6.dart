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

part of '../core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A class to handle reducing operations for 6 Pods.
final class PodReducer6 {
  PodReducer6._();

  /// Reduces 6 Pods into a [ChildPod].
  static ChildPod<Object, C> reduce<C extends Object, P1 extends Object, P2 extends Object,
      P3 extends Object, P4 extends Object, P5 extends Object, P6 extends Object>(
    TResponderFn6<P1, P2, P3, P4, P5, P6> responder,
    TReducerFn6<C, P1, P2, P3, P4, P5, P6> reducer,
  ) {
    return ChildPod<Object, C>(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<GenericPod<Object>> _toList<
      P1 extends Object,
      P2 extends Object,
      P3 extends Object,
      P4 extends Object,
      P5 extends Object,
      P6 extends Object>(TResponderFn6<P1, P2, P3, P4, P5, P6> responder) {
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
  static C _reduce<C extends Object, P1 extends Object, P2 extends Object, P3 extends Object,
      P4 extends Object, P5 extends Object, P6 extends Object>(
    TResponderFn6<P1, P2, P3, P4, P5, P6> responder,
    TReducerFn6<C, P1, P2, P3, P4, P5, P6> reducer,
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

typedef TResponderFn6<P1 extends Object, P2 extends Object, P3 extends Object, P4 extends Object,
        P5 extends Object, P6 extends Object>
    = (
  GenericPod<P1> p1,
  GenericPod<P2> p2,
  GenericPod<P3> p3,
  GenericPod<P4> p4,
  GenericPod<P5> p5,
  GenericPod<P6> p6,
)
        Function();

typedef TReducerFn6<C extends Object, P1 extends Object, P2 extends Object, P3 extends Object,
        P4 extends Object, P5 extends Object, P6 extends Object>
    = C Function(
  GenericPod<P1> p1,
  GenericPod<P2> p2,
  GenericPod<P3> p3,
  GenericPod<P4> p4,
  GenericPod<P5> p5,
  GenericPod<P6> p6,
);
