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

import 'package:flutter/foundation.dart';

import 'package:df_cleanup/df_cleanup.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin that provides disposal management for Pods.
abstract class PodDisposable<T> extends ChangeNotifier
    with DisposeMixin, WillDisposeMixin
    implements PodListenable<T> {
  /// To be called called immediately before [dispose] if defined.
  final TOnBeforeDispose<T>? onBeforeDispose;

  PodDisposable({this.onBeforeDispose});

  /// A flag indicating whether the Pod has been disposed.
  bool _isDisposed = false;

  /// Whether this [Pod] has been disposed of or not.
  @nonVirtual
  bool get isDisposed => this._isDisposed;

  @override
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

  /// Calls [onBeforeDispose] then dipsoses this [PodListenable] and sets
  /// [isDisposed] to `true`. Successive calls to this method will be ignored.
  @override
  @mustCallSuper
  void dispose() {
    if (!_isDisposed) {
      onBeforeDispose?.call(value);
      super.dispose();
      this._isDisposed = true;
    } else {
      // todo: Log warning!
    }
  }
}
