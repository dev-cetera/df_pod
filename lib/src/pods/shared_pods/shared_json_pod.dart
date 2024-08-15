//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
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
      toValue: (value) => value != null ? jsonDecode(value) : null,
    );
    await instance.refresh();
    return instance;
  }

  static Future<TSharedTempJsonPod> temp(String key) async {
    final instance = TSharedTempJsonPod(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) => value != null ? jsonDecode(value) : null,
    );
    await instance.refresh();
    return instance;
  }

  static Future<TSharedGlobalJsonPod> global(String key) async {
    final instance = TSharedGlobalJsonPod(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) => value != null ? jsonDecode(value) : null,
    );
    await instance.refresh();
    return instance;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedJsonPod = SharedPod<String, Map<String, dynamic>>;
typedef TSharedTempJsonPod = SharedTempPod<String, Map<String, dynamic>>;
typedef TSharedGlobalJsonPod = SharedGlobalPod<String, Map<String, dynamic>>;
