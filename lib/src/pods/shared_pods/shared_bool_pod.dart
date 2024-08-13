//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '../../_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SharedBoolPodCreator {
  const SharedBoolPodCreator._();
  static Future<SharedBoolPod> local(String key) async {
    final instance = SharedBoolPod(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }

  static Future<SharedBoolPod> temp(String key) async {
    final instance = SharedBoolPod.temp(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }

  static Future<SharedBoolPod> global(String key) async {
    final instance = SharedBoolPod.global(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }
}

typedef SharedBoolPod = SharedPod<bool, bool>;
