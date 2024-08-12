//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. See LICENSE file
// in root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';

import '_index.g.dart';

part '_child_pod.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A versatile alternative to [ValueNotifier].
///
/// It is designed to hold a single value and notifies listeners not only when
/// the value itself changes but also when mutable states within the value
/// change.
///
/// ### Limitations
///
/// Listeners will not be notified when mutable state within the value itself
/// change:
///
/// ```dart
/// final pod = Pod<List<int>>([0, 1, 2]);
/// pod.value.add(3); // This will NOT notify listeners
/// ```
///
/// ### Solutions
///
/// 1. Notifying listeners with `refresh`:
///
/// ```dart
/// pod.value.add(3);
/// pod.refresh(); // This will notify listeners
/// ```
///
/// 2. Notifying listeners with `set`:
///
/// ```dart
/// pod.set([3, 4, 5]); // This will notify listeners
/// ```
///
/// 3. Notifying listeners with `update`:
///
/// ```dart
/// pod.update((e) => e..add(3)); // This will notify listeners
/// ```
///
/// 4. Notifying listeners with `call` or `updateValue`:
///
/// ```dart
/// // These will notify listeners
/// pod().add(3);
/// pod.updateValue.add(3);
/// ```
///
/// ### Parameters:
///
/// - `value`: The initial value for the Pod.
/// - `temp`: An optional flag to mark the Pod as temporary.

class Pod<T> extends BindWithMixinPodListenable<T> {
  //
  //
  //

  /// Whether this Pod is marked as temporary. Pods marked as temporary are
  /// disposed by consumers like [PodBuilder] when they are no longer needed.
  bool markedAsTemp;

  //
  //
  //

  /// Holds the latest value temporarily during asynchronous updates, ensuring
  /// this Pod's value is always current.
  T? _cachedValue;

  //
  //
  //

  /// Whether this Pod is disposable. If `false`, the Pod will not be disposed
  /// when [dispose] is called. Instead, it will continue to exist until the
  /// application is closed.
  bool disposable;

  //
  //
  //

  /// Creates a `Pod<T>`.
  ///
  /// ### Parameters:
  ///
  /// - `value`: The initial value for the Pod.
  /// - `temp`: An optional flag to mark the Pod as temporary.
  /// - `disposable`: Whether this Pod can be disposed or not.
  /// - `bindWith`: The class to bind itself with. This means this Pod will
  /// dispose when this class disposes.
  Pod(
    super.value, {
    bool temp = false,
    this.disposable = true,
  })  : markedAsTemp = temp,
        assert(
          temp && disposable == true || !temp,
          'Temporary Pods must be disposable.',
        );

  //
  //
  //

  /// A flag indicating whether the Pod has been disposed.
  bool _isDisposed = false;

  /// Whether the Pod has been disposed.
  bool get isDisposed => this._isDisposed;

  //
  //
  //

  /// Casts [other] to `Pod<T>`.
  static Pod<T> cast<T>(PodListenable<T> other) => other as Pod<T>;

  //
  //
  //

  /// Creates a temporary `Pod<T>`.
  ///
  /// - `value`: The initial value for the Pod.
  Pod.temp(T value) : this(value, temp: true);

  //
  //
  //

  /// Reduces many [Pod] - [instances] to a single [ChildPod] instance via
  /// [reducer]. Optionally provide [updateParents] to define how parent Pods
  /// should be updated when this Pod changes.
  static ChildPod<A, B> fromMany<A, B>(
    List<Pod<A>> instances,
    B Function(ManyPods<A> instances) reducer,
    List<A> Function(List<A> parentValues, B childValue)? updateParents,
  ) {
    return reduceManyPods(
      instances,
      reducer,
      updateParents,
    );
  }

  /// Reduces a tuple of 2 [Pod] * [instances]to a single [ChildPod] instance via
  /// [reducer]. Optionally provide [updateParents] to define how parent Pods
  /// should be updated when this Pod changes.
  static ChildPod<dynamic, T> from2<T, A, B>(
    Pods2<A, B> instances,
    T Function(Pods2<A, B> instances) reducer,
    (A?, B?) Function(Tuple2<A, B> parentValues, T childValue)? updateParents,
  ) {
    return reduce2Pods(
      instances,
      reducer,
      updateParents,
    );
  }

  /// Reduces a tuple of 3 [Pod] * [instances]to a single [ChildPod] instance via
  /// [reducer]. Optionally provide [updateParents] to define how parent Pods
  /// should be updated when this Pod changes.
  static ChildPod<dynamic, T> from3<T, A, B, C>(
    Pods3<A, B, C> instances,
    T Function(Pods3<A, B, C> instances) reducer,
    (A?, B?, C?) Function(Tuple3<A, B, C> parentValues, T childValue)? updateParents,
  ) {
    return reduce3Pods(
      instances,
      reducer,
      updateParents,
    );
  }

  /// Reduces a tuple of 4 [Pod] * [instances]to a single [ChildPod] instance via
  /// [reducer]. Optionally provide [updateParents] to define how parent Pods
  /// should be updated when this Pod changes.
  static ChildPod<dynamic, T> from4<T, A, B, C, D>(
    Pods4<A, B, C, D> instances,
    T Function(Pods4<A, B, C, D> instances) reducer,
    (A?, B?, C?, D?) Function(Tuple4<A, B, C, D> parentValues, T childValue)? updateParents,
  ) {
    return reduce4Pods(
      instances,
      reducer,
      updateParents,
    );
  }

  /// Reduces a tuple of 5 [Pod] * [instances]to a single [ChildPod] instance via
  /// [reducer]. Optionally provide [updateParents] to define how parent Pods
  /// should be updated when this Pod changes.
  static ChildPod<dynamic, T> from5<T, A, B, C, D, E>(
    Pods5<A, B, C, D, E> instances,
    T Function(Pods5<A, B, C, D, E> instances) reducer,
    (A?, B?, C?, D?, E?) Function(
      Tuple5<A, B, C, D, E> parentValues,
      T childValue,
    )? updateParents,
  ) {
    return reduce5Pods(
      instances,
      reducer,
      updateParents,
    );
  }

  /// Reduces a tuple of 7 [Pod] * [instances]to a single [ChildPod] instance via
  /// [reducer]. Optionally provide [updateParents] to define how parent Pods
  /// should be updated when this Pod changes.
  static ChildPod<dynamic, T> from6<T, A, B, C, D, E, F>(
    Pods6<A, B, C, D, E, F> instances,
    T Function(Pods6<A, B, C, D, E, F> instances) reducer,
    (A?, B?, C?, D?, E?, F?) Function(
      Tuple6<A, B, C, D, E, F> parentValues,
      T childValue,
    )? updateParents,
  ) {
    return reduce6Pods(
      instances,
      reducer,
      updateParents,
    );
  }

  /// Reduces a tuple of 7 [Pod] * [instances]to a single [ChildPod] instance via
  /// [reducer]. Optionally provide [updateParents] to define how parent Pods
  /// should be updated when this Pod changes.
  static ChildPod<dynamic, T> from7<T, A, B, C, D, E, F, G>(
    Pods7<A, B, C, D, E, F, G> instances,
    T Function(Pods7<A, B, C, D, E, F, G> instances) reducer,
    (A?, B?, C?, D?, E?, F?, G?) Function(
      Tuple7<A, B, C, D, E, F, G> parentValues,
      T childValue,
    )? updateParents,
  ) {
    return reduce7Pods(
      instances,
      reducer,
      updateParents,
    );
  }

  //
  //
  //

  /// Gets this Pod's value without notifying any listeners.
  ///
  ///
  /// ### Limitations
  ///
  /// If you want to change the mutable state within the value and notify
  /// listeners, use [set], [update], [refresh] or [call] instead.
  ///
  /// ### Solutions
  ///
  /// 1. Notifying listeners with `refresh`:
  ///
  /// ```dart
  /// final pod = Pod<List<int>>([0, 1, 2]);
  /// pod.value.add(3);
  /// pod.refresh(); // This will notify listeners
  /// ```
  ///
  /// 2. Notifying listeners with `set`:
  ///
  /// ```dart
  /// pod.set([4, 5, 6]); // This will notify listeners
  /// ```
  ///
  /// 3. Notifying listeners with `update`:
  ///
  /// ```dart
  /// pod.update((list) => list..add(4)); // This will notify listeners
  /// ```
  ///
  /// 4. Notifying listeners with `call` or `updateValue`:
  ///
  /// ```dart
  /// // These will notify listeners
  /// pod().add(3);
  /// pod.updateValue.add(3);
  @override
  T get value => _cachedValue ?? super.value;

  //
  //
  //

  /// Sets this Pod's value and notifies any listeners.
  ///
  /// ### Limitations
  ///
  /// If you want to change the mutable state within the value and notify
  /// listeners, use [set], [update], [refresh], [call] or [updateValue]
  /// instead.
  ///
  /// ### Solutions
  ///
  /// 1. Notifying listeners with `refresh`:
  ///
  /// ```dart
  /// final pod = Pod<List<int>>([0, 1, 2]);
  /// pod.value.add(3);
  /// pod.refresh(); // This will notify listeners
  /// ```
  ///
  /// 2. Notifying listeners with `set`:
  ///
  /// ```dart
  /// pod.set([4, 5, 6]); // This will notify listeners.
  /// ```
  ///
  /// 3. Notifying listeners with `update`:
  ///
  /// ```dart
  /// pod.update((list) => list..add(4)); // This will notify listeners.
  /// ```
  ///
  /// 4. Notifying listeners with `call` or `updateValue`:
  ///
  /// ```dart
  /// // These will notify listeners
  /// pod().add(3);
  /// pod.updateValue.add(3);
  ///
  /// ### Parameters:
  ///
  /// - `newValue`: The new value/state for the Pod.
  @override
  set value(T newValue) => this.set(newValue);

  //
  //
  //

  /// Gets this Pod's value and notifies any listeners.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final pod = Pod<List<int>>([0, 1, 2]);
  /// pod().add(3); // This will notify listeners.
  /// ```
  T call() => updateValue;

  //
  //
  //

  /// Gets this Pod's value and notifies any listeners.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final pod = Pod<List<int>>([0, 1, 2]);
  /// pod.updateValue.add(3); // This will notify listeners.
  /// ```
  T get updateValue {
    Future.delayed(Duration.zero, notifyListeners);
    return value;
  }

  //
  //
  //

  /// Set this Pod's value asynchronously and notfies any listeners after the
  /// current build phase to allow you to make state changes during the build
  /// phase.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final pod = Pod<int>(0);
  /// pod.set(1);
  /// ```
  ///
  /// ### Parameters:
  ///
  /// - `newValue`: The new value/state for the Pod.
  Future<void> set(T newValue) async {
    _cachedValue = newValue;
    await Future.delayed(Duration.zero, () {
      super.value = _cachedValue ?? newValue;
      notifyListeners();
    });
  }

  //
  //
  //

  /// Update this Pod's value asynchronously and notfies any listeners after the
  /// current build phase to allow you to make state changes during the build
  /// phase.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final pod = Pod<List<int>>([0, 1, 2]);
  /// pod.update((e) => e..add(3));
  /// ```
  ///
  /// ### Parameters:
  ///
  /// - `transformer`: A function that takes updates the current value/state of
  /// the Pod.
  Future<void> update(T Function(T oldValue) updater) async {
    final newValue = updater(value);
    await this.set(newValue);
  }

  //
  //
  //

  /// Refresh this Pod's value asynchronously and notfies any listeners after
  /// the current build phase to allow you to make state changes during the build
  /// phase.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// final pod = Pod<List<int>>([0, 1, 2]);
  /// pod.value.add(3);
  /// pod.refresh();
  /// ```
  Future<void> refresh() async {
    await Future.delayed(Duration.zero, notifyListeners);
  }

  //
  //
  //

  /// Adds a [child] to this Pod.
  void _addChild(ChildPod child) {
    if (!child.parents.contains(this)) {
      throw WrongParentPodException();
    }
    if ($children.contains(child)) {
      throw ChildAlreadyAddedPodException();
    }
    addListener(child.refresh);
    $children.add(child);
  }

  //
  //
  //

  /// Removes a [child] from this Pod.
  void _removeChild(ChildPod child) {
    final didRemove = $children.remove(child);
    if (!didRemove) {
      throw NoRemoveChildPodException();
    }
    removeListener(child.refresh);
  }

  //
  //
  //

  /// Maps this Pod to a new Pod using the specified [reducer]. Optionally,
  /// provide [updateParents] to define how parent Pods should be updated when
  /// this Pod changes.
  ChildPod<T, B> map<B>(
    B Function(T value) reducer, [
    List<T> Function(List parentValues, B childValue)? updateParents,
  ]) {
    return ChildPod<T, B>(
      parents: [this],
      reducer: (e) => reducer(e.first),
      updateParents: updateParents,
    );
  }

  /// Maps this Pod to a new temp Pod using the specified [reducer]. Optionally,
  /// provide [updateParents] to define how parent Pods should be updated when
  /// this Pod changes.
  ChildPod<T, B> mapToTemp<B>(
    B Function(T value) reducer, [
    List<T> Function(List parentValues, B childValue)? updateParents,
  ]) {
    return ChildPod<T, B>(
      parents: [this],
      reducer: (e) => reducer(e.first),
      updateParents: updateParents,
      temp: true,
    );
  }

  //
  //
  //

  /// Adds a listener to this Pod that is called only once.
  ///
  /// ### Parameters:
  ///
  /// - `listener`: The listener to be called only once.
  @override
  void addSingleExecutionListener(VoidCallback listener) {
    late final VoidCallback templistener;
    templistener = () {
      listener();
      removeListener(templistener);
    };
    addListener(templistener);
  }

  //
  //
  //

  /// Disposes this Pod and removes all listeners if it is marked as temporary.
  ///
  /// This automatically by consumers like [PodBuilder] to dispose their Pods
  /// that are marked as temporary.
  ///
  /// Custom widgets that accept a Pod as a parameter can leverage this method
  /// to automatically manage the lifecycle of temporary Pods. By calling this
  /// method in the widget's dispose function, it ensures that temporary Pods
  /// are appropriately disposed of when the widget itself is disposed,
  /// maintaining resource efficiency and avoiding memory leaks.
  ///
  /// ### Example:
  ///
  /// ```dart
  /// @override
  /// void dispose() {
  ///   super.dispose();
  ///   myPod.disposeIfMarkedAsTemp();
  /// }
  @override
  void disposeIfMarkedAsTemp() {
    if (markedAsTemp) {
      dispose();
    }
  }

  //
  //
  //

  @override
  void dispose() {
    if (!_isDisposed) {
      if (disposable) {
        super.dispose();
        this._isDisposed = true;
      } else {
        throw DoNotDisposePodException();
      }
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class DoNotDisposePodException extends PodException {
  DoNotDisposePodException()
      : super(
          '"dispose" was called on a Pod that was explicitly maked as non-disposable.',
        );
}

class WrongParentPodException extends PodException {
  WrongParentPodException()
      : super(
          "The child's parent must be this Pod instance.",
        );
}

class ChildAlreadyAddedPodException extends PodException {
  ChildAlreadyAddedPodException()
      : super(
          'The child is already added to this Pod.',
        );
}

class NoRemoveChildPodException extends PodException {
  NoRemoveChildPodException()
      : super(
          'Cannot remove a child that is not added to this Pod.',
        );
}
