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

import 'package:flutter/foundation.dart' show ValueListenable;

import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension ValueListenableX<T extends Object> on ValueListenable<T> {
  /// Returns the Pod as a [ValueListenable].
  ValueListenable<T> asValueListenable() {
    return this;
  }

  /// Casts the [ValueListenable] to a [DisposablePod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  DisposablePod<T> asDisposablePod() {
    return this as DisposablePod<T>;
  }

  /// Casts the [ValueListenable] to a [RootPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  RootPod<T> asRootPod() {
    return this as RootPod<T>;
  }

  /// Casts the [ValueListenable] to a [ChildPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  ChildPod<TParent, T> asChildPod<TParent extends Object>() {
    return this as ChildPod<TParent, T>;
  }

  /// Casts the [ValueListenable] to a [SharedPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  SharedPod<T, TRawValue> asSharedPod<TRawValue extends Object>() {
    return this as SharedPod<T, TRawValue>;
  }

  /// Casts the [ValueListenable] to a [GenericPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  GenericPod<T> asGenericPod() {
    return this as GenericPod<T>;
  }

  /// Casts the [ValueListenable] to a [ProtectedPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  ProtectedPod<T> asProtectedPod() {
    return this as ProtectedPod<T>;
  }
}
