//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
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
typedef GenericPod<T extends Object> = GenericPodMixin<T>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin for managing [RootPod] and [ChildPod].
mixin GenericPodMixin<T extends Object> on PodNotifier<T>, ValueListenable<T> {
  //
  //
  //

  /// Returns the value of the Pod when the [test] returns `true`.
  Resolvable<T> cond(bool Function(T value) test) {
    final finisher = SafeCompleter<T>();
    final check = () {
      if (test(value)) {
        finisher.complete(value).end();
      }
    };
    check();
    if (finisher.isCompleted) {
      return Sync.okValue(value);
    } else {
      addStrongRefListener(strongRefListener: check);
      return finisher.resolvable().then((e) {
        removeListener(check);
        return e;
      });
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
