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

import '/src/_index.g.dart';

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
class PodListBuilder<T> extends StatelessWidget {
  //
  //
  //

  /// The list of `Pod` objects that this builder listens to.
  final Iterable<TFutureOrPod<T>> podList;

  //
  //
  //

  /// An optional child widget that can be used within the [builder] function.
  final TOnDataBuilder<TPodDataList<T?>> builder;

  //
  //
  //

  /// A function to rebuild the widget based on the data received from
  /// [podList].
  final Widget? child;

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
  Widget build(BuildContext context) {
    final temp = this.podList;
    if (temp is List<PodListenable<T>>) {
      return _PodListBuilder(
        key: key,
        podList: temp,
        builder: builder,
        onDispose: onDispose,
        child: child,
      );
    }
    return FutureBuilder(
      future: () async {
        return await Future.wait(
          temp.map(
            (e) => () async {
              return e;
            }(),
          ),
        );
      }(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data != null) {
          return _PodListBuilder(
            key: key,
            podList: data,
            builder: builder,
            onDispose: onDispose,
            child: child,
          );
        } else {
          return builder(
            context,
            List<T?>.filled(temp.length, null),
            child,
          );
        }
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodListBuilder<T> extends StatefulWidget {
  //
  //
  //

  final TPodList<T> podList;

  //
  //
  //

  final Widget? child;

  //
  //
  //

  final TOnDataBuilder<TPodDataList<T>> builder;

  //
  //
  //

  final void Function()? onDispose;

  //
  //
  //

  const _PodListBuilder({
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
  State<_PodListBuilder> createState() => _PodListBuilderState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodListBuilderState<T> extends State<_PodListBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild;
  late Iterable<T> _values;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _values = widget.podList.map((e) => e.value);
    _addListenerToPods(widget.podList);
  }

  //
  //
  //

  @override
  void didUpdateWidget(_PodListBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.podList != widget.podList) {
      _removeListenerFromPods(oldWidget.podList);
      _values = widget.podList.map((e) => e.value);
      _addListenerToPods(widget.podList);
    }
  }

  //
  //
  //

  void _addListenerToPods(TPodList<T> pods) {
    for (final pod in pods) {
      pod.addListener(_valueChanged);
    }
  }

  //
  //
  //

  void _removeListenerFromPods(TPodList<T> pods) {
    for (final pod in pods) {
      pod.removeListener(_valueChanged);
    }
  }

  //
  //
  //

  void _valueChanged() {
    if (mounted) {
      setState(() {
        _values = widget.podList.map((e) => e.value);
      });
    }
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _values,
      _staticChild,
    );
  }

  //
  //
  //

  @override
  void dispose() {
    for (final pod in widget.podList) {
      pod.removeListener(_valueChanged);
      letAsOrNull<PodDisposableMixin<T>>(pod)?.disposeIfTemp();
    }
    widget.onDispose?.call();
    super.dispose();
  }
}
