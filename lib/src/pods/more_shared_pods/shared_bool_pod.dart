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

final class SharedBoolPodCreator {
  const SharedBoolPodCreator._();

  static Future<TSharedBoolPod> create(String key, {bool? initialValue}) {
    // Provide a non-nullable default for the required `initialValue`.
    final finalInitialValue = initialValue ?? false;

    return TSharedBoolPod.create(
      key,
      // If storage is null, return the default value.
      fromValue: (rawValue) => rawValue ?? finalInitialValue,
      toValue: (value) => value,
      initialValue: finalInitialValue,
    );
  }

  static Async<TSharedProtectedBoolPod> protected(
    String key, {
    bool? initialValue,
  }) {
    // Provide a non-nullable default for the required `initialValue`.
    final finalInitialValue = initialValue ?? false;
    return TSharedProtectedBoolPod.create(
      key,
      // If storage is null, return the default value.
      fromValue: (rawValue) => rawValue ?? finalInitialValue,
      toValue: (value) => value,
      initialValue: finalInitialValue,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedBoolPod = SharedPod<bool, bool>;
typedef TSharedProtectedBoolPod = SharedProtectedPod<bool, bool>;
