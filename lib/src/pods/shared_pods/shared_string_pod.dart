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

final class SharedStringPodCreator {
  const SharedStringPodCreator._();
  static Future<SharedStringPod> local(
    String key, {
    bool disposable = true,
    bool temp = false,
  }) async {
    final instance = SharedStringPod(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }

  static Future<SharedStringPod> temp(
    String key, {
    bool disposable = true,
    bool temp = false,
  }) async {
    final instance = SharedStringPod.temp(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }

  static Future<SharedStringPod> global(
    String key, {
    bool disposable = true,
    bool temp = false,
  }) async {
    final instance = SharedStringPod.global(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }
}

typedef SharedStringPod = SharedPod<String, String>;
