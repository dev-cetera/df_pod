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
  static Future<_SharedJsonPod> local(String key) async {
    final instance = _SharedJsonPod(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) => value != null ? jsonDecode(value) : null,
    );
    await instance.refresh();
    return instance;
  }

  static Future<_SharedJsonPod> temp(String key) async {
    final instance = _SharedJsonPod.temp(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) => value != null ? jsonDecode(value) : null,
    );
    await instance.refresh();
    return instance;
  }

  static Future<_SharedJsonPod> global(String key) async {
    final instance = _SharedJsonPod.global(
      key,
      fromValue: (rawValue) => jsonEncode(rawValue),
      toValue: (value) => value != null ? jsonDecode(value) : null,
    );
    await instance.refresh();
    return instance;
  }
}

typedef _SharedJsonPod = SharedPod<String, Map<String, dynamic>>;
