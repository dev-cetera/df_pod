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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TOnValueBuilder<T, S extends OnValueSnapshot<T>> = Widget Function(
  BuildContext context,
  S snapshot,
);

class BuilderSnapshot<T> {
  final Widget? child;

  BuilderSnapshot({
    required this.child,
  });
}

class OnValueSnapshot<T> extends BuilderSnapshot<T> {
  final T value;

  OnValueSnapshot({
    required this.value,
    required super.child,
  });
}

typedef TOnLoadingBuilder<S extends OnLoadingSnapshot> = Widget Function(
  BuildContext context,
  S snapshot,
);

class OnLoadingSnapshot extends BuilderSnapshot {
  final Duration elapsed;
  OnLoadingSnapshot({
    required super.child,
    required this.elapsed,
  });
}

typedef TOnNoValueBuilder<S extends OnNoValueSnapshot> = Widget Function(
  BuildContext context,
  S snapshot,
);

class OnNoValueSnapshot<T> extends BuilderSnapshot<T> {
  OnNoValueSnapshot({
    required super.child,
  });
}
