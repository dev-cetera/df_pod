//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of '../parts.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A class to handle reducing operations for 3 Pods.
final class PodReducer3 {
  PodReducer3._();

  /// Reduces 3 Pods into a [ChildPod].
  static ChildPod<dynamic, C> reduce<C, P1, P2, P3>(
    TResponderFn3<P1, P2, P3> responder,
    TNullableReducerFn3<C, P1, P2, P3> reducer,
  ) {
    return ChildPod<dynamic, C>._local(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Reduces 3 Pods into a temporary [ChildPod].
  static ChildPod<dynamic, C> reduceToTemp<C, P1, P2, P3>(
    TResponderFn3<P1, P2, P3> responder,
    TNullableReducerFn3<C, P1, P2, P3> reducer,
  ) {
    return ChildPod<dynamic, C>._temp(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<AnyPod<dynamic>?> _toList<P1, P2, P3>(
    TResponderFn3<P1, P2, P3> responder,
  ) {
    final response = responder.call();
    return [
      response.$1,
      response.$2,
      response.$3,
    ];
  }

  /// Reduces the values from 3 Pods using the provided reducer function.
  static C _reduce<C, P1, P2, P3>(
    TResponderFn3<P1, P2, P3> responder,
    TNullableReducerFn3<C, P1, P2, P3> reducer,
  ) {
    final response = responder();
    return reducer(
      response.$1,
      response.$2,
      response.$3,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn3<P1, P2, P3> = (
  AnyPod<P1>? p1,
  AnyPod<P2>? p2,
  AnyPod<P3>? p3,
)
    Function();

typedef TNullableReducerFn3<C, P1, P2, P3> = C Function(
  AnyPod<P1>? p1,
  AnyPod<P2>? p2,
  AnyPod<P3>? p3,
);

typedef TReducerFn3<C, P1, P2, P3> = C Function(
  AnyPod<P1> p1,
  AnyPod<P2> p2,
  AnyPod<P3> p3,
);
