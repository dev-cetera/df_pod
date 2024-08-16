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

  Widget builder(CallbackBuilderSnapshot<T> snapshot) {
    return _builder<T>(
      onValueBuilder,
      onLoadingBuilder,
      onNoUsableValueBuilder,
      snapshot,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Widget _builder<T>(
  TOnValueBuilder<T?, CallbackBuilderSnapshot<T>> onValueBuilder,
  TOnLoadingBuilder? onLoadingBuilder,
  TOnNoValueBuilder? onNoUsableValueBuilder,
  CallbackBuilderSnapshot<T> snapshot,
) {
  Widget? widget;
  if (snapshot.hasValue) {
    if (snapshot.hasUsableValue) {
      widget = onValueBuilder(snapshot);
    } else {
      widget = onNoUsableValueBuilder?.call(
        OnNoValueSnapshot(
          context: snapshot.context,
          child: snapshot.child,
        ),
      );
    }
  } else {
    widget = onLoadingBuilder?.call(
      OnLoadingSnapshot(
        context: snapshot.context,
        child: snapshot.child,
      ),
    );
  }
  widget ??= const SizedBox.shrink();
  return widget;
}
