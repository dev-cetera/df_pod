//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SharedBoolPodCreator {
  const SharedBoolPodCreator._();
  static Future<TSharedBoolPod> local(String key) async {
    final instance = TSharedBoolPod(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }

  static Future<TSharedTempBoolPod> temp(String key) async {
    final instance = TSharedTempBoolPod(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }

  static Future<TSharedGlobalBoolPod> global(String key) async {
    final instance = TSharedGlobalBoolPod(
      key,
      fromValue: (rawValue) => rawValue,
      toValue: (value) => value,
    );
    await instance.refresh();
    return instance;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedBoolPod = SharedPod<bool, bool>;
typedef TSharedTempBoolPod = SharedTempPod<bool, bool>;
typedef TSharedGlobalBoolPod = SharedGlobalPod<bool, bool>;
