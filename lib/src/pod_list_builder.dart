//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. See LICENSE file
// in root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:flutter/widgets.dart';

import '_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A widget that listens to a list of [Pod] instances and rebuilds whenever
/// any of their values/states change.
///
/// ### Parameters:
///
/// - `key`: An optional key to use for the widget.
/// - `podList`: The list of `Pod` objects that this builder listens to.
/// - `builder`: A function that rebuilds the widget based on the current
///   states of the observed Pods. It receives the build context, the optional
///   `child` widget, and the valued from the observed `podList`.
/// - `child`: An optional child widget that is passed to the `builder` and,
///   useful for optimization if the child is
///   part of a larger widget that does not need to rebuild.
/// - `onDispose`: An optional function to call when the widget is disposed.
class PodListBuilder extends StatefulWidget {
  //
  //
  //

  /// The list of `Pod` objects that this builder listens to.
  final TPodList podList;

  //
  //
  //

  /// An optional child widget that can be used within the [builder] function.
  final Widget? child;

  //
  //
  //

  /// A function to rebuild the widget based on the data received from
  /// [podList].
  final Widget Function(
    BuildContext context,
    Widget? child,
    TPodDataList data,
  ) builder;

  //
  //
  //

  /// An optional function to call when the widget is disposed.
  final void Function()? onDispose;

  //
  //
  //

  /// Creates a `PodListBuilder` widget.
  ///
  /// ### Parameters:
  ///
  /// - `key`: An optional key to use for the widget.
  /// - `podList`: The list of `Pod` objects that this builder listens to.
  /// - `builder`: A function that rebuilds the widget based on the current
  ///   states of the observed Pods. It receives the build context, the optional
  ///   `child` widget, and the valued from the observed `podList`.
  /// - `child`: An optional child widget that is passed to the `builder`,
  ///   useful for optimization if the child is
  ///   part of a larger widget that does not need to rebuild.
  /// - `onDispose`: An optional function to call when the widget is disposed.
  const PodListBuilder({
    super.key,
    required this.podList,
    required this.builder,
    this.child,
    this.onDispose,
  });

  //
  //
  //

  @override
  State<PodListBuilder> createState() => _PodListBuilderState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodListBuilderState extends State<PodListBuilder> {
  //
  //
  //

  late final Widget? _staticChild;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _addListenerToPods(widget.podList);
  }

  //
  //
  //

  @override
  void didUpdateWidget(PodListBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    _removeListenerFromPods(oldWidget.podList);
    _addListenerToPods(widget.podList);
  }

  //
  //
  //

  void _addListenerToPods(TPodList pods) {
    for (final pod in pods) {
      pod?.addListener(_update);
    }
  }

  //
  //
  //

  void _removeListenerFromPods(TPodList pods) {
    for (final pod in pods) {
      pod?.removeListener(_update);
    }
  }

  //
  //
  //

  void _update() {
    if (mounted) {
      setState(() {});
    }
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final values = widget.podList.map((e) => e?.value);
    return widget.builder(
      context,
      _staticChild,
      values,
    );
  }

  //
  //
  //

  @override
  void dispose() {
    for (final pod in widget.podList) {
      pod?.removeListener(_update);
      pod?.disposeIfMarkedAsTemp();
    }
    widget.onDispose?.call();
    super.dispose();
  }
}
