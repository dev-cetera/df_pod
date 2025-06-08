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

final class SharedStringListPodCreator {
  const SharedStringListPodCreator._();
  static Future<TSharedStringListPod> create(
    String key, {
    List<String>? initialValue,
  }) {
    final finalInitialValue = initialValue ?? const [];
    return TSharedStringListPod.create(
      key,
      fromValue: (rawValue) => rawValue ?? finalInitialValue,
      toValue: (value) => value,
      initialValue: finalInitialValue,
    );
  }

  static Async<TSharedProtectedStringListPod> protected(
    String key, {
    List<String>? initialValue,
  }) {
    final finalInitialValue = initialValue ?? const [];
    return TSharedProtectedStringListPod.create(
      key,
      fromValue: (rawValue) => rawValue ?? finalInitialValue,
      toValue: (value) => value,
      initialValue: finalInitialValue,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedStringListPod = SharedPod<List<String>, List<String>>;
typedef TSharedProtectedStringListPod =
    SharedProtectedPod<List<String>, List<String>>;
