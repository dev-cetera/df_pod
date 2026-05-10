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

/// A class to handle reducing operations for 1 Pod.
final class PodReducer1 {
  PodReducer1._();

  /// Reduces 1 Pod into a [ChildPod]. The user-supplied [responder] is
  /// invoked exactly once per refresh — its output is cached for the
  /// reducer call instead of being re-invoked, so side-effectful responders
  /// (e.g. DI lookups) do not run twice per parent fire.
  static ChildPod<Object, C> reduce<C extends Object, P1 extends Object>(
    TResponderFn1<P1> responder,
    TNullableReducerFn1<C, P1> reducer,
  ) {
    late (GenericPod<P1>,) cached;
    return ChildPod<Object, C>(
      responder: () {
        cached = responder();
        return [cached.$1];
      },
      reducer: (_) => reducer(cached.$1),
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn1<P1 extends Object> = (GenericPod<P1> p1,) Function();

typedef TNullableReducerFn1<C extends Object, P1 extends Object> =
    C Function(GenericPod<P1> p1);

typedef TReducerFn1<C extends Object, P1 extends Object> =
    C Function(GenericPod<P1> p1);
