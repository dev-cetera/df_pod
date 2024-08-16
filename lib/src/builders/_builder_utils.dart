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

typedef TOnValueBuilder<T, P extends OnValueSnapshot<T>> = Widget Function(
  P params,
);

abstract base class BuilderSnapshot<T> {
  final BuildContext context;
  final Widget? child;

  BuilderSnapshot({
    required this.context,
    required this.child,
  });
}

abstract base class OnValueSnapshot<T> extends BuilderSnapshot<T> {
  final T value;

  OnValueSnapshot({
    required super.context,
    required this.value,
    required super.child,
  });
}

typedef TOnLoadingBuilder<T, P extends OnLoadingSnapshot<T>> = Widget Function(
  P params,
);

abstract base class OnLoadingSnapshot<T> extends BuilderSnapshot<T> {
  OnLoadingSnapshot({
    required super.context,
    required super.child,
  });
}

typedef TOnNoValueBuilder<T, P extends OnNoValueSnapshot<T>> = Widget Function(
  P params,
);

abstract base class OnNoValueSnapshot<T> extends BuilderSnapshot<T> {
  OnNoValueSnapshot({
    required super.context,
    required super.child,
  });
}
