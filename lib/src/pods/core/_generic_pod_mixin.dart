//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An alias for [GenericPod].
typedef GenericPod<T extends Object> = GenericPodMixin<T>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin for managing [RootPod] and [ChildPod].
mixin GenericPodMixin<T extends Object> on PodNotifier<T>, ValueListenable<T> {
  //
  //
  //

  /// Returns the value of the Pod when the [test] returns `true`.
  ///
  /// The internal listener self-removes the moment [test] succeeds, so
  /// dropping the returned [Resolvable] without awaiting it does not leak
  /// a listener — earlier versions only removed the listener inside the
  /// `then` callback, which never ran when the caller discarded the result.
  Resolvable<T> cond(bool Function(T value) test) {
    final finisher = SafeCompleter<T>();
    late final VoidCallback check;
    check = () {
      if (test(value)) {
        finisher.complete(value).end();
        removeListener(check);
      }
    };
    check();
    if (finisher.isCompleted) {
      return Sync.okValue(value);
    } else {
      addStrongRefListener(strongRefListener: check);
      return finisher.resolvable();
    }
  }

  final _children = <ChildPod<Object, Object>>{};

  void _addChild(ChildPod<Object, Object> child) {
    if (!_children.contains(child)) {
      // ignore: invalid_use_of_visible_for_testing_member
      addStrongRefListener(strongRefListener: child._refresh);
      _children.add(child);
    }
  }

  void _removeChild(ChildPod<Object, Object> child) {
    final didRemove = _children.remove(child);
    if (didRemove) {
      removeListener(child._refresh);
    }
  }

  bool _set(T newValue, {bool notifyImmediately = true}) {
    if (!isDefinitelyComparableOrEquatable(newValue) || newValue != value) {
      value = newValue;
      if (notifyImmediately) {
        notifyListeners();
      } else {
        // Avoid "setState() or markNeedsBuild() called during build" warning.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!isDisposed) {
            notifyListeners();
          }
        });
      }
      return true;
    }
    return false;
  }

  /// Reduces the current Pod and [other] into a single [ChildPod].
  ChildPod<Object, C> reduce<C extends Object, O extends Object>(
    GenericPod<O> other,
    TReducerFn2<C, T, O> reducer,
  ) {
    return PodReducer2.reduce<C, T, O>(
      () => (this, other),
      (a, b) => reducer(a, b),
    );
  }

  /// Maps `this` [GenericPod] to a new [ChildPod] using the specified [reducer].
  ChildPod<T, B> map<B extends Object>(B Function(T value) reducer) {
    return ChildPod<T, B>(
      responder: () => [this],
      reducer: (_) => reducer(value),
    );
  }

  /// Disposes all children before disposing `this`.
  @override
  void dispose() {
    disposeChildren();
    super.dispose();
  }

  /// Disposes and removes all children.
  ///
  /// Note: [ChildPod.dispose] already walks `_parents` and calls
  /// `parent._removeChild(this)`, which mutates `_children` from underneath
  /// us — that's why we iterate a snapshot. Calling `_removeChild` again
  /// here would be a no-op (the child has already been pulled from the set
  /// and its listener removed), so the loop body just disposes.
  @protected
  void disposeChildren() {
    final copy = Set.of(_children);
    for (final child in copy) {
      child.dispose();
    }
  }
}
