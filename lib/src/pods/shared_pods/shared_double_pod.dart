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

final class SharedDoublePodCreator {
  const SharedDoublePodCreator._();
  static Future<SharedDoublePod> local(String key) async {
    final instance = SharedDoublePod(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }

  static Future<SharedDoublePod> temp(String key) async {
    final instance = SharedDoublePod.temp(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }

  static Future<SharedDoublePod> global(String key) async {
    final instance = SharedDoublePod.global(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }
}

typedef SharedDoublePod = SharedPod<double, double>;
