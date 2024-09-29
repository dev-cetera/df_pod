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
    Iterable<T?> options, {
    T? initialValue,
  }) async {
    final instance = TSharedEnumPod<T>(
      key,
      fromValue: (value) {
        return options.firstWhere(
          (e) => e?.name.toLowerCase() == value?.toLowerCase(),
          orElse: () => null,
        );
      },
      toValue: (rawValue) => rawValue?.name,
    );
    await instance.refresh();
    return instance;
  }

  static Future<TSharedprotectedEnumPod<T>> protected<T extends Enum>(
    String key,
    Iterable<T?> options, {
    T? initialValue,
  }) async {
    final instance = TSharedprotectedEnumPod<T>(key,
        fromValue: (value) {
          return options.firstWhere(
            (e) => e?.name.toLowerCase() == value?.toLowerCase(),
            orElse: () => null,
          );
        },
        toValue: (rawValue) => rawValue?.name,
        initialValue: initialValue);
    await instance.refresh();
    return instance;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedEnumPod<T extends Enum> = SharedPod<T, String>;
typedef TSharedprotectedEnumPod<T extends Enum> = SharedProtectedPod<T, String>;
