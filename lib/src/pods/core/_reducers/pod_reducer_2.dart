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

/// A class to handle reducing operations for 2 Pods.
final class PodReducer2 {
  PodReducer2._();

  /// Reduces 2 Pods into a [ChildPod]. See `PodReducer1.reduce` — the same
  /// single-invocation guarantee applies here.
  static ChildPod<Object, C> reduce<
    C extends Object,
    P1 extends Object,
    P2 extends Object
  >(TResponderFn2<P1, P2> responder, TNullableReducerFn2<C, P1, P2> reducer) {
    late (GenericPod<P1>, GenericPod<P2>) cached;
    return ChildPod<Object, C>(
      responder: () {
        cached = responder();
        return [cached.$1, cached.$2];
      },
      reducer: (_) => reducer(cached.$1, cached.$2),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn2<P1 extends Object, P2 extends Object> =
    (GenericPod<P1> p1, GenericPod<P2> p2) Function();

typedef TNullableReducerFn2<
  C extends Object,
  P1 extends Object,
  P2 extends Object
> = C Function(GenericPod<P1> p1, GenericPod<P2> p2);

typedef TReducerFn2<C extends Object, P1 extends Object, P2 extends Object> =
    C Function(GenericPod<P1> p1, GenericPod<P2> p2);
