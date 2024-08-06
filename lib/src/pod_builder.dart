//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. See LICENSE file
// in root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async';

import 'package:flutter/widgets.dart';

import '_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A widget that listens to a [Pod] and rebuilds whenever the Pod's value/state
/// changes.
///
/// ### Parameters:
///
/// - `key`: An optional key to use for the widget.
/// - `pod`: The Pod that this builder listens to.
/// - `builder`: A function that rebuilds the widget based on the current
///   state of the observed Pod. It receives the build context, the optional
///   `child` widget, and the value from the observed `pod`.
/// - `child`: An optional child widget that is passed to the `builder` and,
///   useful for optimization if the child is
///   part of a larger widget that does not need to rebuild.
/// - `onDispose`: An optional function to call when the widget is disposed.
class PodBuilder<T> extends StatelessWidget {
  //
  //
  //

  /// The Pod that this builder listens to.
  final FutureOr<PodListenable<T>?>? pod;

  //
  //
  //

  /// A function to rebuild the widget based on the data received from [pod].
  final Widget Function(
    BuildContext context,
    Widget? child,
    T? data,
  ) builder;

  //
  //
  //

  /// An optional static child widget that is passed to the [builder].
  final Widget? child;

  //
  //
  //

  /// An optional function to call when the widget is disposed.
  final void Function()? onDispose;

  //
  //
  //

  /// Constructs a `PodBuilder` widget.
  ///
  /// ### Parameters:
  ///
  /// - `key`: An optional key to use for the widget.
  /// - `pod`: The Pod that this builder listens to.
  /// - `builder`: A function that rebuilds the widget based on the current
  ///   state of the observed Pod. It receives the build context, the optional
  ///   `child` widget, and the value from the observed `pod`.
  /// - `child`: An optional child widget that is passed to the `builder` and
  ///   useful for optimization if the child is part of a larger widget that
  ///   does not need to rebuild.
  /// - `onDispose`: An optional function to call when the widget is disposed.
  const PodBuilder({
    super.key,
    this.pod,
    required this.builder,
    this.child,
    this.onDispose,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final temp = pod;
    if (temp is PodListenable<T>?) {
      return _PodBuilder(
        key: key,
        pod: temp,
        builder: builder,
        onDispose: onDispose,
        child: child,
      );
    }
    return FutureBuilder(
      future: temp,
      builder: (context, snapshot) {
        return _PodBuilder(
          key: key,
          pod: snapshot.data,
          builder: builder,
          onDispose: onDispose,
          child: child,
        );
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodBuilder<T> extends StatefulWidget {
  //
  //
  //

  final PodListenable<T>? pod;

  //
  //
  //

  final Widget Function(
    BuildContext context,
    Widget? child,
    T? data,
  ) builder;

  //
  //
  //

  final Widget? child;

  //
  //
  //

  final void Function()? onDispose;

  //
  //
  //

  const _PodBuilder({
    super.key,
    this.pod,
    required this.builder,
    this.child,
    this.onDispose,
  });

  //
  //
  //

  @override
  State<_PodBuilder<T>> createState() => _PodBuilderState<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodBuilderState<T> extends State<_PodBuilder<T>> {
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
    widget.pod?.addListener(_update);
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
    final data = widget.pod?.value;
    return widget.builder(
      context,
      _staticChild,
      data,
    );
  }

  //
  //
  //

  @override
  void dispose() {
    widget.pod?.removeListener(_update);
    widget.pod?.disposeIfMarkedAsTemp();
    widget.onDispose?.call();
    super.dispose();
  }
}
