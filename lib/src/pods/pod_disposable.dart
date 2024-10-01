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

/// An extension of [ValueListenable], providing a foundational layer for Pods.
///
/// The [PodListenable] class serves as a simplified interface to Pods,
/// designed specifically for passing to [PodBuilder] or other supported
/// builders.
///
/// It restricts access to modification methods, focusing solely on the
/// listenable aspect without exposing setters or updaters.
///
/// This abstraction is useful for scenarios where you want to expose only
/// necessary functionalities, ensuring that developers interact with the Pod's
/// state in a controlled manner, preventing accidental changes.
///
/// [PodListenable] is intended for use in UI components where you need to
/// respond to state changes without altering the state directly. In contrast,
/// regular Pods provide methods like `set` or `update` for state modifications.
///
/// ### Example:
///
/// ```dart
/// PodListenable<int> pNumber = Pod<int>(55);
/// ```
///
/// In this example, `pNumber` is limited to the interface provided by
/// [PodListenable], ensuring that it can only be used for listening to changes,
/// while retaining the ability to cast back to any Pod if advanced operations
/// are needed, e.g.:
///
/// ```dart
/// (pNumber as Pod).set(2);
/// ```
abstract class PodListenable<T> extends WeakChangeNotifier
    with DisposeMixin, WillDisposeMixin
    implements ValueListenable<T> {
  /// A flag indicating whether the Pod has been disposed.
  bool _isDisposed = false;

  /// Whether this [Pod] has been disposed of or not.
  @nonVirtual
  bool get isDisposed => this._isDisposed;

  @Deprecated('Deprecated: Please use `addStrongRefListener` instead.')
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

  /// Dipsoses this [PodListenable] and sets [isDisposed] to `true`.
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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension CastPodListenableX<T> on PodListenable<T> {
  /// Returns the Pod as a [PodListenable].
  PodListenable<T> asPodListenable() {
    return this;
  }

  /// Casts the [PodListenable] to a [RootPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  RootPod<T> asRootPod() {
    return this as RootPod<T>;
  }

  /// Casts the [PodListenable] to a [ChildPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  ChildPod<TParent, T> asChildPod<TParent>() {
    return this as ChildPod<TParent, T>;
  }

  /// Casts the [PodListenable] to a [SharedPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  SharedPod<T, TRawValue> asSharedPod<TRawValue>() {
    return this as SharedPod<T, TRawValue>;
  }

  /// Casts the [PodListenable] to a [GenericPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  GenericPod<T> asGenericPod() {
    return this as GenericPod<T>;
  }

  /// Casts the [PodListenable] to a [ProtectedPod].
  ///
  /// Throws a [TypeError] if the cast cannot be performed.
  ProtectedPod<T> asProtectedPod() {
    return this as ProtectedPod<T>;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An alias for [PodListenable].
typedef P<T> = PodListenable<T>;

typedef FutureListenable<T> = FutureOr<PodListenable<T>>;
