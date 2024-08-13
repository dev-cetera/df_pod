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

/// A widget that rebuilds whenever any of the [Pod]s passed to its builder
/// changes.
///
/// ### Parameters:
///
/// - `key`: An optional key to use for the widget.
/// - `child`: An optional child widget that is passed to the `builder` function.
/// - `initialValues`: The initial values for the Pods.
/// - `builder`: A function that is invoked initially and triggers a widget
///   rebuild whenever any of the provided Pods change.
/// - `onDispose`: An optional function to call when the widget is disposed.
class PodListWidget<T> extends StatefulWidget {
  //
  //
  //

  /// An optional static child widget that is passed to the [builder].
  final Widget? child;

  //
  //
  //

  /// The initial value for the Pod.
  final Iterable<T> initialValues;

  //
  //
  //

  /// A function that is invoked initially and triggers a widget rebuild
  /// whenever any of the provided Pods change.
  final TOnDataBuilder<TPodList<T>> builder;

  //
  //
  //

  /// An optional function to call when the widget is disposed.
  final void Function()? onDispose;

  //
  //
  //

  /// Constructs a `PodListWidget` widget.
  ///
  /// ### Parameters:
  ///
  /// - `key`: An optional key to use for the widget.
  /// - `child`: An optional child widget that is passed to the `builder` function.
  /// - `initialValues`: The initial values for the Pods.
  /// - `builder`: A function that is invoked initially and triggers a widget
  ///   rebuild whenever any of the provided Pods change.
  /// - `onDispose`: An optional function to call when the widget is disposed.
  const PodListWidget({
    super.key,
    this.child,
    required this.initialValues,
    required this.builder,
    this.onDispose,
  });

  //
  //
  //

  @override
  State<PodListWidget<T>> createState() => _PodListWidgetState<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodListWidgetState<T> extends State<PodListWidget<T>> {
  //
  //
  //

  late final _podList = widget.initialValues.map((e) => Pod<T>.temp(e));
  late final Widget? _staticChild;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return PodListBuilder(
      key: widget.key,
      podList: _podList,
      child: _staticChild,
      builder: (context, _, child) => widget.builder(
        context,
        _podList,
        child,
      ),
    );
  }

  //
  //
  //

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }
}
