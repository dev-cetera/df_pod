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

/// A class to handle reducing operations for 7 Pods.
final class PodReducer7 {
  PodReducer7._();

  /// Reduces 7 Pods into a [ChildPod].
  static ChildPod<Object, C> reduce<
    C extends Object,
    P1 extends Object,
    P2 extends Object,
    P3 extends Object,
    P4 extends Object,
    P5 extends Object,
    P6 extends Object,
    P7 extends Object
  >(
    TResponderFn7<P1, P2, P3, P4, P5, P6, P7> responder,
    TReducerFn7<C, P1, P2, P3, P4, P5, P6, P7> reducer,
  ) {
    late (
      GenericPod<P1>,
      GenericPod<P2>,
      GenericPod<P3>,
      GenericPod<P4>,
      GenericPod<P5>,
      GenericPod<P6>,
      GenericPod<P7>,
    )
    cached;
    return ChildPod<Object, C>(
      responder: () {
        cached = responder();
        return [
          cached.$1,
          cached.$2,
          cached.$3,
          cached.$4,
          cached.$5,
          cached.$6,
          cached.$7,
        ];
      },
      reducer: (_) => reducer(
        cached.$1,
        cached.$2,
        cached.$3,
        cached.$4,
        cached.$5,
        cached.$6,
        cached.$7,
      ),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn7<
  P1 extends Object,
  P2 extends Object,
  P3 extends Object,
  P4 extends Object,
  P5 extends Object,
  P6 extends Object,
  P7 extends Object
> =
    (
      GenericPod<P1> p1,
      GenericPod<P2> p2,
      GenericPod<P3> p3,
      GenericPod<P4> p4,
      GenericPod<P5> p5,
      GenericPod<P6> p6,
      GenericPod<P7> p7,
    )
    Function();

typedef TReducerFn7<
  C extends Object,
  P1 extends Object,
  P2 extends Object,
  P3 extends Object,
  P4 extends Object,
  P5 extends Object,
  P6 extends Object,
  P7 extends Object
> =
    C Function(
      GenericPod<P1> p1,
      GenericPod<P2> p2,
      GenericPod<P3> p3,
      GenericPod<P4> p4,
      GenericPod<P5> p5,
      GenericPod<P6> p6,
      GenericPod<P7> p7,
    );
