//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of '../core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A class to handle reducing operations for 1 Pod.
final class PodReducer1 {
  PodReducer1._();

  /// Reduces 1 Pod into a [ChildPod].
  static ChildPod<dynamic, C> reduce<C, P1>(
    TResponderFn1<P1> responder,
    TNullableReducerFn1<C, P1> reducer,
  ) {
    return ChildPod<dynamic, C>._(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<GenericPod<dynamic>?> _toList<P1>(TResponderFn1<P1> responder) {
    final response = responder.call();
    return [
      response.$1,
    ];
  }

  /// Reduces the values from 1 Pod using the provided reducer function.
  static C _reduce<C, P1>(
    TResponderFn1<P1> responder,
    TNullableReducerFn1<C, P1> reducer,
  ) {
    final response = responder();
    return reducer(
      response.$1,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TResponderFn1<P1> = (GenericPod<P1>? p1,) Function();

typedef TNullableReducerFn1<C, P1> = C Function(
  GenericPod<P1>? p1,
);

typedef TReducerFn1<C, P1> = C Function(
  GenericPod<P1> p1,
);
