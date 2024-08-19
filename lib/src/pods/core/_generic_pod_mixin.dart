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

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An alias for [GenericPod].
typedef GenericPod<T> = GenericPodMixin<T>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin for managing [RootPod] and [ChildPod].
mixin GenericPodMixin<T> on PodNotifier<T> {
  //
  //
  //

  final _children = <_ChildPodBase<dynamic, dynamic>>{};

  void _addChild(_ChildPodBase<dynamic, dynamic> child) {
    if (!_children.contains(child)) {
      addListener(child._refresh);
      _children.add(child);
    }
  }

  void _removeChild(_ChildPodBase<dynamic, dynamic> child) {
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
    GenericPod<O> other,
    TReducerFn2<C, T, O> reducer,
  ) {
    return PodReducer2.reduce<C, T, O>(
      () => (this, other),
      (a, b) => reducer(a!, b!),
    );
  }

  /// Maps `this` [GenericPod] to a new [ChildPod] using the specified [reducer].
  ChildPod<T, B> map<B>(B Function(T? value) reducer) {
    return ChildPod<T, B>._(
      responder: () => [this],
      reducer: (e) => reducer(e.firstOrNull),
    );
  }

  /// Disposes all children before disposing `this`.
  @override
  void dispose() {
    this.disposeChildren();
    super.dispose();
  }

  /// Disposes and removes all children.
  @protected
  void disposeChildren() {
    // Copy the set to prevent concurrent modification issues during iteration.
    final copy = Set.of(_children);
    for (final child in copy) {
      child.dispose();
      _removeChild(child);
    }
  }
}
