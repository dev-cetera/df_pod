//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file located in this project's root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of '../core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A class to handle reducing operations for 2 Pods.
final class PodReducer2 {
  PodReducer2._();

  /// Reduces 2 Pods into a [ChildPod].
  static ChildPod<dynamic, C> reduce<C, P1, P2>(
    TResponderFn2<P1, P2> responder,
    TNullableReducerFn2<C, P1, P2> reducer,
  ) {
    return ChildPod<dynamic, C>._(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<GenericPod<dynamic>?> _toList<P1, P2>(
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
  GenericPod<P1>? p1,
  GenericPod<P2>? p2,
)
    Function();

typedef TNullableReducerFn2<C, P1, P2> = C Function(
  GenericPod<P1>? p1,
  GenericPod<P2>? p2,
);

typedef TReducerFn2<C, P1, P2> = C Function(
  GenericPod<P1> p1,
  GenericPod<P2> p2,
);
