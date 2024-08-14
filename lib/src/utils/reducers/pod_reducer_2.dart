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

/// A class to handle reducing operations for 2 Pods.
final class PodReducer2 {
  PodReducer2._();

  /// Reduces 2 Pods into a [ChildPod].
  static ChildPod<dynamic, C> reduce<C, P1, P2>(
    TResponderFn2<P1, P2> responder,
    TNullableReducerFn2<C, P1, P2> reducer,
  ) {
    return ChildPod<dynamic, C>(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Reduces 2 Pods into a temporary [ChildPod].
  static ChildPod<dynamic, C> reduceToTemp<C, P1, P2>(
    TResponderFn2<P1, P2> responder,
    TNullableReducerFn2<C, P1, P2> reducer,
  ) {
    return ChildPod<dynamic, C>.temp(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<AnyPod<dynamic>?> _toList<P1, P2>(
    TResponderFn2<P1, P2> responder,
  ) {
    final response = responder.call();
    return [
      response.$1,
      response.$2,
    ];
  }

  /// Reduces the values from 2 Pods using the provided reducer function.
  static C _reduce<C, P1, P2>(
    TResponderFn2<P1, P2> responder,
    TNullableReducerFn2<C, P1, P2> reducer,
  ) {
    final response = responder();
    return reducer(
      response.$1,
      response.$2,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn2<P1, P2> = (
  AnyPod<P1>? p1,
  AnyPod<P2>? p2,
)
    Function();

typedef TNullableReducerFn2<C, P1, P2> = C Function(
  AnyPod<P1>? p1,
  AnyPod<P2>? p2,
);

typedef TReducerFn2<C, P1, P2> = C Function(
  AnyPod<P1> p1,
  AnyPod<P2> p2,
);
