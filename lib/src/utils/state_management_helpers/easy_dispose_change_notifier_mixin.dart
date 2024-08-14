//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/foundation.dart' show ChangeNotifier, mustCallSuper;

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin that facilitates disposal of ChangeNotifiers for classes that use
/// [DisposeMixin].
mixin EasyDisposeChangeNotifierMixin on DisposeMixin {
  //
  //
  //

  /// Holds a list of [ChangeNotifier]s linked to this parent.
  final _changeNotifiers = <ChangeNotifier>[];

  //
  //
  //

  /// Registers the [child] ChangeNotifier so it will automatically be disposed
  /// when `this` is disposed.
  T registerChild<T extends ChangeNotifier>(T child) {
    _changeNotifiers.add(child);
    return child;
  }

  //
  //
  //

  /// Disposes all registered children before disposing of the parent.
  @mustCallSuper
  @override
  void dispose() {
    for (final changeNotifiers in _changeNotifiers) {
      changeNotifiers.dispose();
    }
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

extension DisposeOnOnChangeNotifierX<T extends ChangeNotifier> on T {
  /// Registers `this` ChangeNotifier with [parent], ensuring it is disposed
  /// when the [parent] is disposed.
  T disposeOn<P extends EasyDisposeChangeNotifierMixin>(P parent) => parent.registerChild(this);
}
