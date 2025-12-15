//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SharedJsonPodCreator {
  const SharedJsonPodCreator._();
  static Future<TSharedJsonPod> create(
    String key, {
    Map<String, Object>? initialValue,
  }) {
    final finalInitialValue = initialValue ?? const {};
    return TSharedJsonPod.create(
      key,
      fromValue: (rawValue) => rawValue != null
          ? jsonDecode(rawValue) as Map<String, Object>
          : finalInitialValue,
      toValue: (value) => jsonEncode(value),
      initialValue: finalInitialValue,
    );
  }

  static Async<TSharedProtectedJsonPod> protected(
    String key, {
    Map<String, Object>? initialValue,
  }) {
    final finalInitialValue = initialValue ?? const {};
    return TSharedProtectedJsonPod.create(
      key,
      fromValue: (rawValue) => rawValue != null
          ? jsonDecode(rawValue) as Map<String, Object>
          : finalInitialValue,
      toValue: (value) => jsonEncode(value),
      initialValue: finalInitialValue,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedJsonPod = SharedPod<Map<String, Object>, String>;
typedef TSharedProtectedJsonPod =
    SharedProtectedPod<Map<String, Object>, String>;
