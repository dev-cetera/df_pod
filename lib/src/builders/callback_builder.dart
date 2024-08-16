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

import '_builder_utils.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A wrapper for the [PodListCallbackBuilder] that provides a simpler
/// solution.
class CallbackBuilder<T> extends StatelessWidget {
  //
  //
  //

  final TPodListCallbackN<T> callback;
  final T? Function() getData;
  final bool Function(T data)? isUsableData;
  final TOnValueBuilder<T?, CallbackBuilderSnapshot<T>> builder;
  final Widget? child;

  //
  //
  //

  const CallbackBuilder({
    super.key,
    required this.callback,
    required this.getData,
    required this.builder,
    this.child,
    this.isUsableData,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return PodListCallbackBuilder(
      callback: callback,
      builder: (parentSnapshot) {
        parentSnapshot.podList;
        final data = getData();
        final hasValue = data is T;
        final hasUsableValue = hasValue && (this.isUsableData?.call(data) ?? true);
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
