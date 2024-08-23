//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:convert';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SharedJsonPodCreator {
  const SharedJsonPodCreator._();
  static Future<TSharedJsonPod> local(String key) async {
    final instance = TSharedJsonPod(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) =>
          value != null ? jsonDecode(value) as Map<String, dynamic> : null,
    );
    await instance.refresh();
    return instance;
  }

  static Future<TSharedTempJsonPod> temp(String key) async {
    final instance = TSharedTempJsonPod(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) =>
          value != null ? jsonDecode(value) as Map<String, dynamic> : null,
    );
    await instance.refresh();
    return instance;
  }

  static Future<TSharedGlobalJsonPod> global(String key) async {
    final instance = TSharedGlobalJsonPod(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) =>
          value != null ? jsonDecode(value) as Map<String, dynamic> : null,
    );
    await instance.refresh();
    return instance;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedJsonPod = SharedPod<String, Map<String, dynamic>>;
typedef TSharedTempJsonPod = SharedTempPod<String, Map<String, dynamic>>;
typedef TSharedGlobalJsonPod = SharedGlobalPod<String, Map<String, dynamic>>;
