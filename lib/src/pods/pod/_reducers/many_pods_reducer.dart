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

/// A final class to handle reducing operations for many Pods.
final class ManyPodsReducer {
  ManyPodsReducer._();

  /// Reduces many Pods into a [ChildPod].
  static ChildPod<T1, T2> reduce<T1, T2>(
    List<Pod<T1>> Function() responder,
    T2 Function(ManyPods<T1> values) reducer,
  ) {
    return ChildPod<T1, T2>._local(
      responder: responder,
      reducer: (_) {
        final response = responder();
        return reducer(ManyPods(response));
      },
    );
  }

  /// Reduces many Pods into a temporary [ChildPod].
  static ChildPod<T1, T2> reduceToTemp<T1, T2>(
    List<Pod<T1>> Function() responder,
    T2 Function(ManyPods<T1> values) reducer,
  ) {
    return ChildPod<T1, T2>._temp(
      responder: responder,
      reducer: (_) {
        final response = responder();
        return reducer(ManyPods(response));
      },
    );
  }
}
