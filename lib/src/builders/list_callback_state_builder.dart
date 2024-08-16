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
  late final createdAt = DateTime.now();

  //
  //
  //

  ListCallbackStateBuilder({
    super.key,
    required this.onValueBuilder,
    this.onLoadingBuilder,
    this.onNoUsableValueBuilder,
    this.child,
  });

  //
  //
  //

  Widget builder(BuildContext context, CallbackBuilderSnapshot<T> snapshot) {
    return _builder<T>(
      context,
      onValueBuilder,
      onLoadingBuilder,
      onNoUsableValueBuilder,
      this,
      snapshot,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Widget _builder<T>(
  BuildContext context,
  TOnValueBuilder<T?, CallbackBuilderSnapshot<T>> onValueBuilder,
  TOnLoadingBuilder? onLoadingBuilder,
  TOnNoValueBuilder? onNoUsableValueBuilder,
  ListCallbackStateBuilder<T> widget,
  CallbackBuilderSnapshot<T> snapshot,
) {
  Widget? result;
  if (snapshot.hasValue) {
    if (snapshot.hasUsableValue) {
      result = onValueBuilder(context, snapshot);
    } else {
      result = onNoUsableValueBuilder?.call(
        context,
        OnNoValueSnapshot(
          child: snapshot.child,
        ),
      );
    }
  } else {
    result = onLoadingBuilder?.call(
      context,
      OnLoadingSnapshot(
        child: snapshot.child,
        createdAt: widget.createdAt,
      ),
    );
  }
  result ??= const SizedBox.shrink();
  return result;
}
