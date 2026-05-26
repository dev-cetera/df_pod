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

abstract class DisposablePod<T extends Object> extends WeakChangeNotifier
    implements ValueListenable<T> {
  /// ❌ Do not use this method directly. Use [addStrongRefListener] instead.
  @override
  @Deprecated(
    'Do not use this method directly. Use [addStrongRefListener] instead',
  )
  void addListener(VoidCallback listener) {
    if (!isDisposed) {
      super.addListener(listener);
    } else {
      Log.alert('Tried to add a listener to a disposed Pod!', tags: {#df_pod});
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    if (!isDisposed) {
      super.removeListener(listener);
    } else {
      Log.alert(
        'Tried to remove a listener from a disposed Pod!',
        tags: {#df_pod},
      );
    }
  }

  @protected
  void Function()? onAfterDispose;

  /// Disposes this [ValueListenable].
  /// Successive calls to this method will be ignored.
  ///
  /// The single source of truth for "is this disposed?" is
  /// [WeakChangeNotifier.isDisposed]. Subclasses must consult that
  /// getter rather than maintaining their own flag.
  @override
  @mustCallSuper
  void dispose() {
    if (!isDisposed) {
      super.dispose();
      try {
        onAfterDispose?.call();
      } catch (e) {
        Log.err(e, tags: {#df_pod});
      }
    } else {
      Log.alert('Tried to dispose a Pod again!', tags: {#df_pod});
    }
  }
}
