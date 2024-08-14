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

/// A class to handle reducing operations for 1 Pod.
final class PodReducer1 {
  PodReducer1._();

  /// Reduces 1 Pod into a [ChildPod].
  static ChildPod<dynamic, C> reduce<C, P1>(
    TResponderFn1<P1> responder,
    TNullableReducerFn1<C, P1> reducer,
  ) {
    return ChildPod<dynamic, C>(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Reduces 1 Pod into a temporary [ChildPod].
  static ChildPod<dynamic, C> reduceToTemp<C, P1>(
    TResponderFn1<P1> responder,
    TNullableReducerFn1<C, P1> reducer,
  ) {
    return ChildPod<dynamic, C>.temp(
      responder: () => _toList(responder),
      reducer: (_) => _reduce(responder, reducer),
    );
  }

  /// Converts the response from the responder function into a list of Pods.
  static List<PodMixin<dynamic>?> _toList<P1>(TResponderFn1<P1> responder) {
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

typedef TResponderFn1<P1> = (PodMixin<P1>? p1,) Function();

typedef TNullableReducerFn1<C, P1> = C Function(
  PodMixin<P1>? p1,
);

typedef TReducerFn1<C, P1> = C Function(
  PodMixin<P1> p1,
);
