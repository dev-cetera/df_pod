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

  /// Decodes [rawValue] as a JSON object. Returns [fallback] if [rawValue] is
  /// null, malformed, not an object, or contains non-[Object] values. The
  /// fallback path matters because storage can be corrupted by an interrupted
  /// write or by an older app version writing an incompatible shape.
  static Map<String, Object> _decodeOrFallback(
    String? rawValue,
    Map<String, Object> fallback,
  ) {
    if (rawValue == null) return fallback;
    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is Map) {
        final result = <String, Object>{};
        for (final entry in decoded.entries) {
          final k = entry.key;
          final v = entry.value;
          if (k is String && v != null) {
            result[k] = v as Object;
          }
        }
        return result;
      }
      return fallback;
    } on FormatException {
      Log.alert(
        'SharedJsonPod: discarded malformed JSON for key, falling back to '
        'initialValue',
        tags: {#df_pod},
      );
      return fallback;
    }
  }

  static Future<TSharedJsonPod> create(
    String key, {
    Map<String, Object>? initialValue,
  }) {
    final finalInitialValue = initialValue ?? const {};
    return TSharedJsonPod.create(
      key,
      fromValue: (rawValue) => _decodeOrFallback(rawValue, finalInitialValue),
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
      fromValue: (rawValue) => _decodeOrFallback(rawValue, finalInitialValue),
      toValue: (value) => jsonEncode(value),
      initialValue: finalInitialValue,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedJsonPod = SharedPod<Map<String, Object>, String>;
typedef TSharedProtectedJsonPod =
    SharedProtectedPod<Map<String, Object>, String>;
