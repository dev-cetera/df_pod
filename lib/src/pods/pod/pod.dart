//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:tuple/tuple.dart';

import '/src/utils/_reducers.dart';
import '/src/_index.g.dart';

part '_child_pod.dart';
part '_static_constructors.dart';
part '_temp_static_constructors.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base class Pod<T> extends BindWithMixinPodNotifier<T> {
  //
  //
  //

  /// Holds the latest value temporarily during asynchronous updates, ensuring
  /// this Pod's value is always current.
  T? _cachedValue;

  Pod(super.value);

  Pod.temp(super.value) : super.temp();

  Pod.global(super.value) : super.global();

  //
  //
  //

  /// Casts [other] to [Pod].
  // ignore: invalid_use_of_visible_for_testing_member
  static Pod<T> cast<T>(PodListenable<T> other) =>
      other.asPodNotifier().asPod();

  //
  //
  //

  static const fromMany = _fromMany;
  static const from2 = _from2;
  static const from3 = _from3;
  static const from4 = _from4;
  static const from5 = _from5;
  static const from6 = _from6;
  static const from7 = _from7;

  static const tempFromMany = _tempFromMany;
  static const tempFrom2 = _tempFrom2;
  static const tempFrom3 = _tempFrom3;
  static const tempFrom4 = _tempFrom4;
  static const tempFrom5 = _tempFrom5;
  static const tempFrom6 = _tempFrom6;
  static const tempFrom7 = _tempFrom7;

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
    return ChildPod<T, B>.temp(
      parents: [this],
      reducer: (e) => reducer(e.first),
      updateParents: updateParents,
    );
  }
}
