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

abstract class ListCallbackStateBuilder<T> extends StatelessWidget {
  //
  //
  //

  final TOnValueBuilder<T?, CallbackBuilderSnapshot<T>> onValueBuilder;
  final TOnLoadingBuilder? onLoadingBuilder;
  final TOnNoValueBuilder? onNoUsableValueBuilder;
  final Widget? child;

  //
  //
  //

  const ListCallbackStateBuilder({
    super.key,
    required this.onValueBuilder,
    this.onLoadingBuilder,
    this.onNoUsableValueBuilder,
    this.child,
  });

  //
  //
  //

  Widget builder(
    BuildContext context,
    Widget? child,
    CallbackBuilderSnapshot<T> snapshot,
  ) {
    return _builder<T>(
      onValueBuilder,
      onLoadingBuilder,
      onNoUsableValueBuilder,
      context,
      snapshot,
      child,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Widget _builder<T>(
  TOnValueBuilder<T?, CallbackBuilderSnapshot<T>> onValueBuilder,
  TOnLoadingBuilder? onLoadingBuilder,
  TOnNoValueBuilder? onNoUsableValueBuilder,
  BuildContext context,
  CallbackBuilderSnapshot<T> snapshot,
  Widget? child,
) {
  Widget? widget;
  if (snapshot.hasValue) {
    if (snapshot.hasUsableValue) {
      widget = onValueBuilder(snapshot);
    } else {
      widget = onNoUsableValueBuilder?.call(
        OnNoValueSnapshot(
          context: context,
          child: child,
        ),
      );
    }
  } else {
    widget = onLoadingBuilder?.call(
      OnLoadingSnapshot(
        context: context,
        child: child,
      ),
    );
  }
  widget ??= const SizedBox.shrink();
  return widget;
}
