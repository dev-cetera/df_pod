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

mixin AnyPod<T> on PodNotifier<T> {
  //
  //
  //

  final _children = <AnyPod>{};

  void _addChild(ChildPod child) {
    if (!_children.contains(child)) {
      addListener(child._refresh);
      _children.add(child);
    }
  }

  void _removeChild(ChildPod child) {
    final didRemove = _children.remove(child);
    if (didRemove) {
      removeListener(child._refresh);
    }
  }

  T? _cachedValue;

  Future<void> _set(T newValue) async {
    if (!isEquatable<T>() || newValue != _value) {
      _cachedValue = newValue;
      await Future.delayed(Duration.zero, () {
        _value = _cachedValue ?? newValue;
        notifyListeners();
      });
    }
  }

  /// Reduces the current Pod and [other] into a single [ChildPod].
  ChildPod<dynamic, C> reduce<C, O>(
    AnyPod<O> other,
    TReducerFn2<C, T, O> reducer,
  ) {
    return PodReducer2.reduce<C, T, O>(
      () => (this, other),
      (a, b) => reducer(a!, b!),
    );
  }

  /// Reduces the current Pod and [other] into a single temporary [ChildPod].
  ChildPod<dynamic, C> reduceToTemp<C, O>(
    AnyPod<O> other,
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

  /// Disposes all children before disposing `this`.
  @override
  void dispose() {
    // Copy the set to prevent concurrent modification issues during iteration.
    final copy = Set.of(_children);
    for (final child in copy) {
      child.dispose();
    }
    super.dispose();
  }
}
