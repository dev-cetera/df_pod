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

/// A widget that rebuilds whenever the [Pod] passed to its builder changes.
///
/// ### Parameters:
///
/// - `key`: An optional key to use for the widget.
/// - `child`: An optional child widget that is passed to the `builder` function.
/// - `initialValue`: The initial value for the Pod.
/// - `builder`: A function that is invoked initially and triggers a widget
///   rebuild whenever the provided Pod changes.
/// - `onDispose`: An optional function to call when the widget is disposed.
class PodWidget<T> extends StatefulWidget {
  //
  //
  //

  /// An optional static child widget that is passed to the [builder].
  final Widget? child;

  //
  //
  //

  /// The initial value for the Pod.
  final T initialValue;

  //
  //
  //

  /// A function that is invoked initially and triggers a widget rebuild
  /// whenever the provided Pod changes.
  final Widget Function(
    BuildContext context,
    Widget? child,
    Pod<T> pod,
  ) builder;

  //
  //
  //

  /// An optional function to call when the widget is disposed.
  final void Function()? onDispose;

  //
  //
  //

  /// Constructs a `PodWidget` widget.
  ///
  /// ### Parameters:
  ///
  /// - `key`: An optional key to use for the widget.
  /// - `child`: An optional child widget that is passed to the `builder` function.
  /// - `initialValue`: The initial value for the Pod.
  /// - `builder`: A function that is invoked initially and triggers a widget
  ///   rebuild whenever the provided [Pod] changes.
  /// - `onDispose`: An optional function to call when the widget is disposed.
  const PodWidget({
    super.key,
    this.child,
    required this.initialValue,
    required this.builder,
    this.onDispose,
  });

  //
  //
  //

  @override
  State<PodWidget<T>> createState() => _PodWidgetState<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodWidgetState<T> extends State<PodWidget<T>> {
  //
  //
  //

  late final _pod = Pod<T>.temp(widget.initialValue);
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
    return PodBuilder(
      key: widget.key,
      pod: _pod,
      child: _staticChild,
      builder: (context, child, _) => widget.builder(
        context,
        child,
        _pod,
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
