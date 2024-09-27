//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An alias for [GenericPod].
typedef GenericPod<T> = GenericPodMixin<T>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin for managing [RootPod] and [ChildPod].
mixin GenericPodMixin<T> on PodNotifier<T>, PodDisposable<T> {
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

  /// Set the current value to [newValue] if either [T] is not equatable as
  /// deemed by [isEquatable] of if [newValue] is different from the current
  /// value, then schedules [notifyListeners] for the next loop.
  bool _set(T newValue) {
    if (!isEquatable<T>() || newValue != _value) {
      _value = newValue;

      // Delay notifyListeners to the next loop to ensure that listeners
      // added or removed during this loop, will be notified in the next loop.
      // See description of [notifyListeners].
      Future.delayed(Duration.zero, () {
        if (!isDisposed) {
          notifyListeners();
        }
      });
      return true;
    }
    return false;
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
