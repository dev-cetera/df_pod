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
class CallbackBuilder<T> extends StatelessWidget {
  //
  //
  //

  final TPodListCallbackN<T> responder;
  final T? Function() getData;
  final bool Function(T data)? isUsableData;
  final TOnDataBuilder<CallbackBuilderSnapshot<T>> builder;
  final Widget? child;

  //
  //
  //

  const CallbackBuilder({
    super.key,
    required this.responder,
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
      podListCallback: responder,
      builder: (context, _, staticChild) {
        final data = this.getData();
        final hasData = data is T;
        final hasUsableData = hasData && (this.isUsableData?.call(data) ?? true);
        final snapshot = CallbackBuilderSnapshot<T>(
          data: data,
          hasData: hasData,
          hasUsableData: hasUsableData,
        );
        final widget = this.builder(
          context,
          snapshot,
          staticChild,
        );
        return widget;
      },
      child: this.child,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class CallbackBuilderSnapshot<T> {
  //
  //
  //

  final T? data;
  final bool hasData;
  final bool hasUsableData;

  //
  //
  //

  CallbackBuilderSnapshot({
    required this.data,
    required this.hasData,
    required this.hasUsableData,
  });
}
