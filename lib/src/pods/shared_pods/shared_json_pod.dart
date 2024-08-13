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

import '../../_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SharedJsonPodCreator {
  const SharedJsonPodCreator._();
  static Future<SharedJsonPod> local(String key) async {
    final instance = SharedJsonPod(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) => value != null ? jsonDecode(value) : null,
    );
    await instance.refresh();
    return instance;
  }

  static Future<SharedJsonPod> temp(String key) async {
    final instance = SharedJsonPod.temp(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) => value != null ? jsonDecode(value) : null,
    );
    await instance.refresh();
    return instance;
  }

  static Future<SharedJsonPod> global(String key) async {
    final instance = SharedJsonPod.global(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) => value != null ? jsonDecode(value) : null,
    );
    await instance.refresh();
    return instance;
  }
}

typedef SharedJsonPod = SharedPod<String, Map<String, dynamic>>;
