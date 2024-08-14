//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

// ignore_for_file: invalid_use_of_visible_for_testing_member

part of 'parts.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

mixin BasePodMixin<T> implements PodNotifier<T>, BindWithMixinPodNotifier<T> {
  //
  //
  //

  T? _cachedValue;

  //
  //
  //

  Future<void> _set(T newValue) async {
    _cachedValue = newValue;
    await Future.delayed(Duration.zero, () {
      $value = _cachedValue ?? newValue;
      notifyListeners();
    });
  }

  ChildPod<dynamic, C> reduceAndRespond<C, O>(
    BasePodMixin<O>? Function() other,
    C Function(BasePodMixin<T>? p1, BasePodMixin<O>? p2) reducer,
  ) {
    return reduce2Pods(
      () => (this, other()),
      reducer,
    );
  }

  ChildPod<dynamic, C> reduce<C, O>(
    BasePodMixin<O> other,
    C Function(BasePodMixin<T> p1, BasePodMixin<O> p2) reducer,
  ) {
    return reduce2Pods<C, T, O>(
      () => (this, other),
      (a, b) => reducer(a!, b!),
    );
  }

  /// Maps `this` [Pod] to a new [Pod] using the specified [reducer].
  ChildPod<T, B> map<B>(B Function(T? value) reducer) {
    return ChildPod<T, B>(
      responder: () => [this],
      reducer: (e) => reducer(e.firstOrNull),
    );
  }

  /// Maps `this` [Pod] to a new [Pod.temp] using the specified [reducer].
  ChildPod<T, B> mapToTemp<B>(B Function(T? value) reducer) {
    return ChildPod<T, B>.temp(
      responder: () => [this],
      reducer: (e) => reducer(e.firstOrNull),
    );
  }
}
