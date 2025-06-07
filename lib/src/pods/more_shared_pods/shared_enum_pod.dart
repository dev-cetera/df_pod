//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:df_safer_dart/df_safer_dart.dart' show Async;

import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SharedEnumPodCreator {
  const SharedEnumPodCreator._();

  /// Creates a pod that persists an enum value.
  ///
  /// Requires a non-nullable `initialValue` to ensure type safety, as there
  /// is no universal default for enums.
  static Future<TSharedEnumPod<T>> create<T extends Enum>(
    String key, {
    required Iterable<T> options,
    required T initialValue,
  }) {
    return TSharedEnumPod.create(
      key,
      fromValue: (rawValue) {
        if (rawValue == null) return initialValue;
        // Find the enum by its name, or fall back to the initialValue.
        return options.firstWhere(
          (e) => e.name.toLowerCase() == rawValue.toLowerCase(),
          orElse: () => initialValue,
        );
      },
      toValue: (value) => value.name,
      initialValue: initialValue,
    );
  }

  static Async<TSharedProtectedEnumPod<T>> protected<T extends Enum>(
    String key, {
    required Iterable<T> options,
    required T initialValue,
  }) {
    return TSharedProtectedEnumPod.create(
      key,
      fromValue: (rawValue) {
        if (rawValue == null) return initialValue;
        return options.firstWhere(
          (e) => e.name.toLowerCase() == rawValue.toLowerCase(),
          orElse: () => initialValue,
        );
      },
      toValue: (value) => value.name,
      initialValue: initialValue,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedEnumPod<T extends Enum> = SharedPod<T, String>;
typedef TSharedProtectedEnumPod<T extends Enum> = SharedProtectedPod<T, String>;
