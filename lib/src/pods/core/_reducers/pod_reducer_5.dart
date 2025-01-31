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

/// A class to handle reducing operations for 5 Pods.
final class PodReducer5 {
  PodReducer5._();

  /// Reduces 5 Pods into a [ChildPod].
  static ChildPod<dynamic, C> reduce<C, P1, P2, P3, P4, P5>(
    TResponderFn5<P1, P2, P3, P4, P5> responder,
    TNullableReducerFn5<C, P1, P2, P3, P4, P5> reducer,
  ) {
    return ChildPod<dynamic, C>._(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<GenericPod<dynamic>?> _toList<P1, P2, P3, P4, P5>(
    TResponderFn5<P1, P2, P3, P4, P5> responder,
  ) {
    final response = responder.call();
    return [
      response.$1,
      response.$2,
      response.$3,
      response.$4,
      response.$5,
    ];
  }

  /// Reduces the values from 5 Pods using the provided reducer function.
  static C _reduce<C, P1, P2, P3, P4, P5>(
    TResponderFn5<P1, P2, P3, P4, P5> responder,
    TNullableReducerFn5<C, P1, P2, P3, P4, P5> reducer,
  ) {
    final response = responder();
    return reducer(
      response.$1,
      response.$2,
      response.$3,
      response.$4,
      response.$5,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn5<P1, P2, P3, P4, P5> = (
  GenericPod<P1>? p1,
  GenericPod<P2>? p2,
  GenericPod<P3>? p3,
  GenericPod<P4>? p4,
  GenericPod<P5>? p5,
)
    Function();

typedef TNullableReducerFn5<C, P1, P2, P3, P4, P5> = C Function(
  GenericPod<P1>? p1,
  GenericPod<P2>? p2,
  GenericPod<P3>? p3,
  GenericPod<P4>? p4,
  GenericPod<P5>? p5,
);

typedef TReducerFn5<C, P1, P2, P3, P4, P5> = C Function(
  GenericPod<P1> p1,
  GenericPod<P2> p2,
  GenericPod<P3> p3,
  GenericPod<P4> p4,
  GenericPod<P5> p5,
);
