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

import 'package:flutter/widgets.dart';

import 'package:df_will_dispose/df_will_dispose.dart';

import 'package:meta/meta.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A very basic Pod that requires no disposal and works with an ordinary
/// [Builder]. Needs performance testing!
@experimental
class EasyPod<T> {
  //
  //
  //

  final _elements = <Element>{};

  //
  //
  //

  T _value;

  //
  //
  //

  EasyPod(this._value);

  //
  //
  //

  T get([BuildContext? context]) {
    if (context is Element) {
      _elements.add(context);
      ContextStore.of(context).attach(
        this,
        key: hashCode,
        onDetach: (_) {
          _elements.remove(context);
        },
      );
    }
    return _value;
  }

  //
  //
  //

  void update(T Function(T oldValue) updater) {
    _value = updater(_value);
    this._markNeedsBuild();
  }

  //
  //
  //

  void _markNeedsBuild() {
    for (final e in _elements) {
      e.markNeedsBuild();
    }
  }
}
