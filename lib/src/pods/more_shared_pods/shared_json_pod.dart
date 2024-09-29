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
  static Future<TSharedJsonPod> create(
    String key, {
    Map<String, dynamic>? initialValue,
  }) async {
    final instance = TSharedJsonPod(
      key,
      fromValue: (value) => value != null ? jsonDecode(value) as Map<String, dynamic> : null,
      toValue: (rawValue) => jsonEncode(rawValue),
    );
    await instance.refresh();
    return instance;
  }

  static Future<TSharedProtectedJsonPod> protected(
    String key, {
    Map<String, dynamic>? initialValue,
  }) async {
    final instance = TSharedProtectedJsonPod(
      key,
      fromValue: (value) => value != null ? jsonDecode(value) as Map<String, dynamic> : null,
      toValue: (rawValue) => jsonEncode(rawValue),
      initialValue: initialValue,
    );
    await instance.refresh();
    return instance;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedJsonPod = SharedPod<Map<String, dynamic>, String>;
typedef TSharedProtectedJsonPod = SharedProtectedPod<Map<String, dynamic>, String>;
