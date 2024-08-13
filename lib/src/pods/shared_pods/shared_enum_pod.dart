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

final class SharedEnumPodCreator {
  const SharedEnumPodCreator._();
  static Future<_SharedEnumPod<T>> create<T extends Enum>(
    String key,
    Iterable<T?> options,
  ) async {
    final instance = _SharedEnumPod<T>(
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

  static Future<_SharedEnumPod<T>> temp<T extends Enum>(
    String key,
    Iterable<T?> options,
  ) async {
    final instance = _SharedEnumPod<T>.temp(
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

  static Future<_SharedEnumPod<T>> global<T extends Enum>(
    String key,
    Iterable<T?> options,
  ) async {
    final instance = _SharedEnumPod<T>.global(
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

typedef _SharedEnumPod<T extends Enum> = SharedPod<String, T>;
