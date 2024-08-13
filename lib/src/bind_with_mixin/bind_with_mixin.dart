//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/widgets.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A mixin that provides an auto-disposal method for classes that use
/// [DisposeMixin].
mixin BindWithMixin on DisposeMixin {
  //
  //
  //

  /// A list of [ChangeNotifier]s that are bound to `this` parent. Do not
  /// modify this list directly.
  @protected
  final $children = <ChangeNotifier>[];

  //
  //
  //

  /// Binds the ChangeNotifier [child] to `this` parent so that the [child]
  /// will be disposed when `this` is disposed.
  T bindChild<T extends ChangeNotifier>(T child) {
    $children.add(child);
    return child;
  }

  //
  //
  //

  /// Disposes all children that have been bound to `this` parent, before
  /// disposing `this`.
  @override
  void dispose() {
    for (final child in $children) {
      child.dispose();
    }
    super.dispose();
  }
}
