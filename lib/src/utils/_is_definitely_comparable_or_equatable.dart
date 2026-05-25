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

import 'package:equatable/equatable.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Returns `true` when [value]'s runtime type has well-defined `==`
/// (either via [Comparable] / [Equatable] / a value-type primitive, or
/// via Dart 3 structural [Record] equality).
///
/// Pods use this to decide whether to short-circuit a `set(...)` when
/// the new value equals the old: types in this list compare by content;
/// types NOT in this list (custom classes without `==`, [List], [Map],
/// [Set]) compare by identity and would otherwise miss the short-circuit
/// — we choose to over-notify rather than miss notifications.
///
/// Records were added so `(int, int)` and similar tuple types short-
/// circuit on equal content, matching Dart 3 semantics.
bool isDefinitelyComparableOrEquatable(Object? value) {
  return value is Comparable ||
      value is Equatable ||
      value is num ||
      value is bool ||
      value is Enum ||
      value is Symbol ||
      value is Record ||
      value == null;
}
