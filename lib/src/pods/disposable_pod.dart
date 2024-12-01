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

import 'dart:async' show FutureOr;

import 'package:flutter/foundation.dart';

import '/src/_index.g.dart';

import 'package:df_cleanup/df_cleanup.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class DisposablePod<T> extends WeakChangeNotifier
    with DisposeMixin, WillDisposeMixin
    implements ValueListenable<T> {
  /// A flag indicating whether the Pod has been disposed.
  bool _isDisposed = false;

  /// Whether this [Pod] has been disposed of or not.
  @nonVirtual
  bool get isDisposed => this._isDisposed;

  /// ❌ Do not use this method directly. Use [addStrongRefListener] instead.
  @override
  @Deprecated(
    'Do not use this method directly. Use [addStrongRefListener] instead',
  )
  void addListener(VoidCallback listener) {
    if (!_isDisposed) {
      super.addListener(listener);
    } else {
      // todo: Log warning!
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (!_isDisposed) {
      super.removeListener(listener);
    } else {
      // todo: Log warning!
    }
  }

  /// Dipsoses this [ValueListenable] and sets [isDisposed] to `true`.
  /// Successive calls to this method will be ignored.
  @override
  @mustCallSuper
  void dispose() {
    if (!_isDisposed) {
      super.dispose();
      this._isDisposed = true;
    } else {
      // todo: Log warning!
    }
  }
}

@Deprecated('Use DisposablePod<T> instead.')
typedef PodDisposable<T> = DisposablePod<T>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension CastPodListenableX<T> on ValueListenable<T> {
  /// Returns the Pod as a [ValueListenable].
  ValueListenable<T> asValueListenable() {
    return this;
  }

  @Deprecated('Use `asDisposablePod` instead.')
  DisposablePod<T> asPodDisposable() {
    return this as DisposablePod<T>;
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
  ChildPod<TParent, T> asChildPod<TParent>() {
    return this as ChildPod<TParent, T>;
  }

  /// Casts the [ValueListenable] to a [SharedPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  SharedPod<T, TRawValue> asSharedPod<TRawValue>() {
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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TFutureListenable<T> = FutureOr<ValueListenable<T>>;
typedef F<T> = TFutureListenable<T>;

@Deprecated('Use ValueListenable<T> instead.')
typedef PodListenable<T> = ValueListenable<T>;
