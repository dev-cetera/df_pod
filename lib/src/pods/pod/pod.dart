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

import 'package:tuple/tuple.dart';

import '/src/utils/_reducers.dart';
import '/src/_index.g.dart';

part '_static_constructors.dart';
part '_temp_static_constructors.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base class Pod<T> extends BindWithMixinPodNotifier<T> {
  //
  //
  //

  T? _cachedValue;

  Pod(super.value);

  Pod.temp(super.value) : super.temp();

  Pod.global(super.value) : super.global();

  static Pod<T> cast<T>(PodListenable<T> other) => other.asPodNotifier().asPod();

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

  @override
  T get value => _cachedValue ?? super.value;

  @override
  set value(T newValue) => this.set(newValue);

  T get updateValue {
    this.refresh();
    return value;
  }

  Future<void> set(T newValue) async {
    _cachedValue = newValue;
    await Future.delayed(Duration.zero, () {
      super.value = _cachedValue ?? newValue;
      notifyListeners();
    });
  }

  Future<void> update(T Function(T oldValue) updater) async {
    final newValue = updater(value);
    await this.set(newValue);
  }

  Future<void> refresh() async {
    await Future.delayed(Duration.zero, notifyListeners);
  }

  /// Maps `this` [Pod] to a new [Pod] using the specified [reducer].
  ///
  /// Optionally, provide [updateParents] to define how parent Pods should be
  /// updated when this Pod changes.
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

  /// Maps `this` [Pod] to a new [Pod.temp] using the specified [reducer].
  ///
  /// Optionally, provide [updateParents] to define how parent Pods should be
  /// updated when this Pod changes.
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
