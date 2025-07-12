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

final class SharedDoublePodCreator {
  const SharedDoublePodCreator._();

  static Future<TSharedDoublePod> create(String key, {double? initialValue}) {
    final finalInitialValue = initialValue ?? 0.0;
    return TSharedDoublePod.create(
      key,
      fromValue: (rawValue) => rawValue ?? finalInitialValue,
      toValue: (value) => value,
      initialValue: finalInitialValue,
    );
  }

  static Async<TSharedProtectedDoublePod> protected(
    String key, {
    double? initialValue,
  }) {
    final finalInitialValue = initialValue ?? 0.0;
    return TSharedProtectedDoublePod.create(
      key,
      fromValue: (rawValue) => rawValue ?? finalInitialValue,
      toValue: (value) => value,
      initialValue: finalInitialValue,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TSharedDoublePod = SharedPod<double, double>;
typedef TSharedProtectedDoublePod = SharedProtectedPod<double, double>;
