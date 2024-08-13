//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async';

import 'package:df_type/df_type.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// Builds a [Widget] when given a concrete value of a [Pod<T>].
///
/// If the `child` parameter provided to the [PodBuilder] is not
/// null, the same `child` widget is passed back to this [PodBuilder]
/// and should typically be incorporated in the returned widget tree.
///
/// See also:
///
///  - [PodBuilder], a widget which invokes this builder each time a [Pod]
/// changes value.
typedef PodBuilderFunction<T> = ValueWidgetBuilder<T?>;

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
/// - `builder`: A [PodBuilderFunction] which builds a widget whenever [pod]
///    changes or gets refreshed.
/// - `child`: An optional independent widget, that is directly passed to the
///   [builder]. This can be used for optimizations.
/// - `onDispose`: An optional function that is invoked when this [PodBuilder]
///   gets disposed.
///
/// ### See also:
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
  final FutureOr<PodListenable<T>?>? pod;

  //
  //
  //

  /// A [PodBuilderFunction] which builds a widget whenever [pod] changes or
  /// gets refreshed.
  final PodBuilderFunction<T> builder;

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
  final void Function()? onDispose;

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
  /// - `builder`: A [PodBuilderFunction] which builds a widget whenever [pod]
  ///    changes or gets refreshed.
  /// - `child`: An optional independent widget, that is directly passed to the
  ///   [builder]. This can be used for optimizations.
  /// - `onDispose`: An optional function that is invoked when this [PodBuilder]
  ///   gets disposed.
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

/// A custom builder widget similar to [PodListenableBuilder] that supports
/// nullable [pod], an [onDispose] callback, and auto-disposes the [Pod]
/// if marked as temporary.
class _PodBuilder<T> extends StatefulWidget {
  //
  //
  //

  final ValueListenable<T>? pod;

  //
  //
  //

  final PodBuilderFunction<T> builder;

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
  late T? value;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    // Change from ValueListenableBuilder: Set _staticChild in initState.
    _staticChild = widget.child;
    value = widget.pod?.value;
    widget.pod?.addListener(_valueChanged);
  }

  //
  //
  //

  @override
  void didUpdateWidget(_PodBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pod != widget.pod) {
      oldWidget.pod?.removeListener(_valueChanged);
      value = widget.pod?.value;
      widget.pod?.addListener(_valueChanged);
    }
  }

  //
  //
  //

  void _valueChanged() {
    // Change from ValueListenableBuilder: Only do setState if widget is mounted.
    if (mounted) {
      setState(() {
        value = widget.pod?.value;
      });
    }
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final value = widget.pod?.value;
    return widget.builder(
      context,
      value,
      _staticChild,
    );
  }

  //
  //
  //

  @override
  void dispose() {
    widget.pod?.removeListener(_valueChanged);
    // Change from ValueListenableBuilder: Dispose the Pod if marked as
    // temporary.
    letAsOrNull<PodDisposableMixin>(widget.pod)?.disposeIfTemp();
    // Change from ValueListenableBuilder: Invoke a callback on dispose that
    // can be used for debugging of Pod-linking purposes.
    widget.onDispose?.call();
    super.dispose();
  }
}
