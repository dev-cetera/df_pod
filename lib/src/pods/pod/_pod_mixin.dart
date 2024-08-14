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

mixin PodMixin<T> implements PodNotifier<T>, BindWithMixinPodNotifier<T> {
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
      _value = _cachedValue ?? newValue;
      notifyListeners();
    });
  }

  ChildPod<dynamic, C> respondAndReduce<C, O>(
    PodMixin<O>? Function() other,
    TNullableReducerFn2<C, T, O> reducer,
  ) {
    return PodReducer2.reduce<C, T, O>(
      () => (this, other()),
      reducer,
    );
  }

  ChildPod<dynamic, C> respondAndReduceToTemp<C, O>(
    PodMixin<O>? Function() other,
    TNullableReducerFn2<C, T, O> reducer,
  ) {
    return PodReducer2.reduceToTemp<C, T, O>(
      () => (this, other()),
      reducer,
    );
  }

  ChildPod<dynamic, C> reduce<C, O>(
    PodMixin<O> other,
    TReducerFn2<C, T, O> reducer,
  ) {
    return PodReducer2.reduce<C, T, O>(
      () => (this, other),
      (a, b) => reducer(a!, b!),
    );
  }

  ChildPod<dynamic, C> reduceToTemp<C, O>(
    PodMixin<O> other,
    TReducerFn2<C, T, O> reducer,
  ) {
    return PodReducer2.reduceToTemp<C, T, O>(
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
