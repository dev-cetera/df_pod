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

part of '../core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A class to handle reducing operations for 4 Pods.
final class PodReducer4 {
  PodReducer4._();

  /// Reduces 4 Pods into a [ChildPod].
  static ChildPod<Object, C> reduce<C extends Object, P1 extends Object, P2 extends Object,
      P3 extends Object, P4 extends Object>(
    TResponderFn4<P1, P2, P3, P4> responder,
    TReducerFn4<C, P1, P2, P3, P4> reducer,
  ) {
    return ChildPod<Object, C>(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<GenericPod<Object>>
      _toList<P1 extends Object, P2 extends Object, P3 extends Object, P4 extends Object>(
    TResponderFn4<P1, P2, P3, P4> responder,
  ) {
    final response = responder.call();
    return [response.$1, response.$2, response.$3, response.$4];
  }

  /// Reduces the values from 4 Pods using the provided reducer function.
  static C _reduce<C extends Object, P1 extends Object, P2 extends Object, P3 extends Object,
      P4 extends Object>(
    TResponderFn4<P1, P2, P3, P4> responder,
    TReducerFn4<C, P1, P2, P3, P4> reducer,
  ) {
    final response = responder();
    return reducer(response.$1, response.$2, response.$3, response.$4);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn4<P1 extends Object, P2 extends Object, P3 extends Object, P4 extends Object>
    = (
  GenericPod<P1> p1,
  GenericPod<P2> p2,
  GenericPod<P3> p3,
  GenericPod<P4> p4,
)
        Function();

typedef TReducerFn4<C extends Object, P1 extends Object, P2 extends Object, P3 extends Object,
        P4 extends Object>
    = C Function(
  GenericPod<P1> p1,
  GenericPod<P2> p2,
  GenericPod<P3> p3,
  GenericPod<P4> p4,
);
