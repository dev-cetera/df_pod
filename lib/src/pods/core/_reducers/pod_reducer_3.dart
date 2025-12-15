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

/// A class to handle reducing operations for 3 Pods.
final class PodReducer3 {
  PodReducer3._();

  /// Reduces 3 Pods into a [ChildPod].
  static ChildPod<Object, C> reduce<C extends Object, P1 extends Object,
      P2 extends Object, P3 extends Object>(
    TResponderFn3<P1, P2, P3> responder,
    TReducerFn3<C, P1, P2, P3> reducer,
  ) {
    return ChildPod<Object, C>(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<GenericPod<Object>>
      _toList<P1 extends Object, P2 extends Object, P3 extends Object>(
    TResponderFn3<P1, P2, P3> responder,
  ) {
    final response = responder.call();
    return [response.$1, response.$2, response.$3];
  }

  /// Reduces the values from 3 Pods using the provided reducer function.
  static C _reduce<C extends Object, P1 extends Object, P2 extends Object,
      P3 extends Object>(
    TResponderFn3<P1, P2, P3> responder,
    TReducerFn3<C, P1, P2, P3> reducer,
  ) {
    final response = responder();
    return reducer(response.$1, response.$2, response.$3);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn3<P1 extends Object, P2 extends Object, P3 extends Object>
    = (GenericPod<P1> p1, GenericPod<P2> p2, GenericPod<P3> p3) Function();

typedef TReducerFn3<C extends Object, P1 extends Object, P2 extends Object,
        P3 extends Object>
    = C Function(GenericPod<P1> p1, GenericPod<P2> p2, GenericPod<P3> p3);
