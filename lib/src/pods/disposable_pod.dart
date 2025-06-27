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

import 'package:df_log/df_log.dart' show Log;

import 'package:flutter/foundation.dart';

import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class DisposablePod<T extends Object> extends WeakChangeNotifier
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
      Log.alert('Tried to add a listener to a disposed Pod!', {#df_pod});
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (!_isDisposed) {
      super.removeListener(listener);
    } else {
      Log.alert('Tried to remove a listener from a disposed Pod!', {#df_pod});
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
      Log.alert('Tried to dispose a Pod again!', {#df_pod});
    }
  }
}
