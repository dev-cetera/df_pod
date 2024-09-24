//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A widget that stays in sync with a [Pod] and rebuilds by calling [builder]
/// whenever [pod] changes or gets refreshed.
///
/// ### Parameters:
///
/// - `key`: An optional key to use for the widget.
///
/// - `pod`: The [Pod] that triggers rebuilds by invoking the [builder]
///    whenever its value changes or is refreshed. If the [pod] is a future,
///    it will be awaited, and the [builder] will be called once the future
///    completes. While awaiting, the builder receives a `null` value. If [pod]
///    is not a future or it is `null`, its current value or `null` is passed
///    to the [builder].
/// - `builder`: A [TOnValueBuilder] which builds a widget whenever [pod]
///    changes or gets refreshed.
/// - `child`: An optional independent widget, that is directly passed to the
///   [builder]. This can be used for optimizations.
/// - `onDispose`: An optional function that is invoked when this [PodBuilder]
///   gets disposed.
///
/// ### See Also:
///
/// - [ValueListenable], which is what [Pod] is inspired by.
/// - [ValueListenableBuilder], which is what [PodBuilder] is inspired by.
class PodBuilder<T> extends StatelessWidget {
  //
  //
  //

  /// The [Pod] that triggers rebuilds by invoking the [builder] whenever its
  /// value changes or is refreshed. If the [pod] is a future, it will be
  /// awaited, and the [builder] will be called once the future completes. While
  /// awaiting, the builder receives a `null` value. If [pod] is not a future or
  /// it is `null`, its current value or `null` is passed to the [builder].
  final FutureOr<PodListenable<T>> pod;

  //
  //
  //

  /// A [TOnValueBuilder] which builds a widget whenever [pod] changes or
  /// gets refreshed.
  final TOnValueBuilder<T?, PodBuilderSnapshot<T>> builder;

  //
  //
  //

  /// An optional independent widget, that is directly passed to the [builder].
  /// This can be used for optimizations.
  final Widget? child;

  //
  //
  //

  /// An optional function that is invoked when this [PodBuilder] gets disposed.
  final void Function(PodListenable<T> pod)? onDispose;

  //
  //
  //

  /// Constructs a [PodBuilder].
  ///
  /// ### Parameters:
  ///
  /// - `key`: An optional key to use for the widget.
  ///
  /// - `pod`: The [Pod] that triggers rebuilds by invoking the [builder]
  ///    whenever its value changes or is refreshed. If the [pod] is a future,
  ///    it will be awaited, and the [builder] will be called once the future
  ///    completes. While awaiting, the builder receives a `null` value. If [pod]
  ///    is not a future or it is `null`, its current value or `null` is passed
  ///    to the [builder].
  /// - `builder`: A [TOnValueBuilder] which builds a widget whenever [pod]
  ///    changes or gets refreshed.
  /// - `child`: An optional independent widget, that is directly passed to the
  ///   [builder]. This can be used for optimizations.
  /// - `onDispose`: An optional function that is invoked when this [PodBuilder]
  ///   gets disposed.
  const PodBuilder({
    super.key,
    required this.pod,
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
    if (temp is PodListenable<T>) {
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
        final data = snapshot.data;
        if (data != null) {
          return _PodBuilder(
            key: key,
            pod: data,
            builder: builder,
            onDispose: onDispose,
            child: child,
          );
        } else {
          return builder(
            context,
            PodBuilderSnapshot<T>(
              pod: null,
              value: null,
              child: child,
            ),
          );
        }
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A custom builder widget similar to [ValueListenableBuilder] that supports
/// nullable [pod], an [onDispose] callback, and auto-disposes the [Pod]
/// if marked as temporary.
class _PodBuilder<T> extends StatefulWidget {
  //
  //
  //

  final PodListenable<T> pod;

  //
  //
  //

  final TOnValueBuilder<T?, PodBuilderSnapshot<T>> builder;

  //
  //
  //

  final Widget? child;

  //
  //
  //

  final void Function(PodListenable<T> pod)? onDispose;

  //
  //
  //

  const _PodBuilder({
    super.key,
    required this.pod,
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
  late T _value;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _value = widget.pod.value;
    widget.pod.addListener(_valueChanged);
  }

  //
  //
  //

  @override
  void didUpdateWidget(_PodBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pod != widget.pod) {
      oldWidget.pod.removeListener(_valueChanged);
      _value = widget.pod.value;
      widget.pod.addListener(_valueChanged);
    }
  }

  //
  //
  //

  void _valueChanged() {
    if (mounted) {
      setState(() {
        _value = widget.pod.value;
      });
    }
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final snapshot = PodBuilderSnapshot(
      pod: widget.pod,
      value: _value,
      child: _staticChild,
    );
    final result = widget.builder(context, snapshot);
    return result;
  }

  //
  //
  //

  @override
  void dispose() {
    widget.pod.removeListener(_valueChanged);
    widget.onDispose?.call(widget.pod);
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodBuilderSnapshot<T> extends OnValueSnapshot<T?> {
  //
  //
  //

  final PodListenable<T>? pod;

  //
  //
  //

  PodBuilderSnapshot({
    required this.pod,
    required super.value,
    required super.child,
  });

  //
  //
  //

  bool get hasValue => pod != null;
}
