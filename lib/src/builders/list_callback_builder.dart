//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file located in this project's root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/widgets.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A wrapper for the [PodListCallbackBuilder] that provides a simpler
/// solution.
class ListCallbackBuilder<T> extends StatelessWidget {
  //
  //
  //

  final TPodListCallbackN listCallback;
  final T? Function() getValue;
  final bool Function(T data)? isUsableValue;
  final TOnValueBuilder<T?, CallbackBuilderSnapshot<T>> builder;
  final Widget? child;

  //
  //
  //

  const ListCallbackBuilder({
    super.key,
    required this.listCallback,
    required this.getValue,
    required this.builder,
    this.child,
    this.isUsableValue,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return PodListCallbackBuilder(
      listCallback: listCallback,
      builder: (context, parentSnapshot) {
        final value = getValue();
        final hasValue = value is T;
        final hasUsableValue = hasValue && (isUsableValue?.call(value) ?? true);
        final childSnapshot = CallbackBuilderSnapshot<T>(
          podList: parentSnapshot.podList,
          hasValue: hasValue,
          hasUsableValue: hasUsableValue,
          value: value,
          child: parentSnapshot.child,
        );
        final result = builder(context, childSnapshot);
        return result;
      },
      child: this.child,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class CallbackBuilderSnapshot<T> extends OnValueSnapshot<T?> {
  //
  //
  //
  final TPodListN? podList;
  final bool hasValue;
  final bool hasUsableValue;

  //
  //
  //

  CallbackBuilderSnapshot({
    required this.podList,
    required this.hasValue,
    required this.hasUsableValue,
    required super.value,
    required super.child,
  });
}
