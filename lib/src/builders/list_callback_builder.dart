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

/// A wrapper for the [PodListCallbackBuilder] that provides a simpler
/// solution.
class ListCallbackBuilder<T> extends StatelessWidget {
  //
  //
  //

  final TPodListCallbackN<T> listCallback;
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
      builder: (parentSnapshot) {
        parentSnapshot.podList;
        final data = getValue();
        final hasValue = data is T;
        final hasUsableValue =
            hasValue && (this.isUsableValue?.call(data) ?? true);
        final childSnapshot = CallbackBuilderSnapshot<T>(
          podList: parentSnapshot.podList,
          hasValue: hasValue,
          hasUsableValue: hasUsableValue,
          context: context,
          value: data,
          child: child,
        );
        final widget = this.builder(childSnapshot);
        return widget;
      },
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
    required super.context,
    required super.value,
    required super.child,
  });
}
