//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '../../_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SharedEnumPodCreator {
  const SharedEnumPodCreator._();
  static Future<SharedEnumPod<T>> create<T extends Enum>(
    String key,
    Iterable<T?> options, {
    bool disposable = true,
    bool temp = false,
  }) async {
    final instance = SharedEnumPod<T>.empty(
      key,
      disposable: disposable,
      temp: temp,
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

typedef SharedEnumPod<T extends Enum> = SharedPod<String, T>;
