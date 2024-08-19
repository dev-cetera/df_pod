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

class BuilderSnapshot {
  final Widget? child;

  BuilderSnapshot({
    required this.child,
  });
}

class OnValueSnapshot<T> extends BuilderSnapshot {
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
  final DateTime createdAt;
  OnLoadingSnapshot({
    required super.child,
    required this.createdAt,
  });
}

typedef TOnNoValueBuilder<S extends OnNoValueSnapshot<dynamic>> = Widget
    Function(
  BuildContext context,
  S snapshot,
);

class OnNoValueSnapshot<T> extends BuilderSnapshot {
  OnNoValueSnapshot({
    required super.child,
  });
}
