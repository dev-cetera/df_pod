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

base class Pod<T> extends BindWithMixinPodNotifier<T> with BasePodMixin<T> {
  //
  //
  //

  Pod(super.value);

  Pod.temp(super.value) : super.temp();

  Pod.global(super.value) : super.global();

  static Pod<T> cast<T>(PodListenable<T> other) =>
      other.asPodNotifier().asPod();

  T get updateValue {
    this.refresh();
    return value;
  }

  Future<void> set(T newValue) => super._set(newValue);

  Future<void> update(T Function(T oldValue) updater) async {
    final newValue = updater(value);
    await set(newValue);
  }

  Future<void> refresh() async {
    await Future.delayed(Duration.zero, notifyListeners);
  }

  // static ChildPod<dynamic, T> from2<T, T1, T2>(
  //   (BasePodMixin<T1>? p1, BasePodMixin<T2>? p2) Function() responder,
  //   T Function(BasePodMixin<T1>? p1, BasePodMixin<T2>? p2) reducer,
  // ) {
  //   return reduce2Pods<T, T1, T2>(
  //     responder,
  //     reducer,
  //   );
  // }
}
