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

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SharedEnumPodCreator {
  const SharedEnumPodCreator._();
  static Future<TSharedEnumPod<T>> create<T extends Enum>(
    String key,
    Iterable<T?> options,
  ) async {
    final instance = TSharedEnumPod<T>(
      key,
      fromValue: (rawValue) => rawValue?.name,
      toValue: (value) {
        return options.firstWhere(
          (e) => e?.name.toLowerCase() == value?.toLowerCase(),
          orElse: () => null,
        );
      },
    );
    await instance.refresh();
    return instance;
  }

  static Future<TSharedTempEnumPod<T>> temp<T extends Enum>(
    String key,
    Iterable<T?> options,
  ) async {
    final instance = TSharedTempEnumPod<T>(
      key,
      fromValue: (rawValue) => rawValue?.name,
      toValue: (value) {
        return options.firstWhere(
          (e) => e?.name.toLowerCase() == value?.toLowerCase(),
          orElse: () => null,
        );
      },
    );
    await instance.refresh();
    return instance;
  }

  static Future<TSharedGlobalEnumPod<T>> global<T extends Enum>(
    String key,
    Iterable<T?> options,
  ) async {
    final instance = TSharedGlobalEnumPod<T>(
      key,
      fromValue: (rawValue) => rawValue?.name,
      toValue: (value) {
        return options.firstWhere(
          (e) => e?.name.toLowerCase() == value?.toLowerCase(),
          orElse: () => null,
        );
      },
    );
    await instance.refresh();
    return instance;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedEnumPod<T extends Enum> = SharedPod<String, T>;
typedef TSharedTempEnumPod<T extends Enum> = SharedTempPod<String, T>;
typedef TSharedGlobalEnumPod<T extends Enum> = SharedGlobalPod<String, T>;
