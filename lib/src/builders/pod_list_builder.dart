//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;

import 'package:flutter/widgets.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodListBuilder<T> extends StatelessWidget {
  //
  //
  //

  final Iterable<TFutureListenable<T>> podList;
  final TOnValueBuilder<Iterable<T?>, PodListBuilderSnapshot<T>> builder;
  final Duration? debounceDuration;
  final void Function(Iterable<ValueListenable<T>> podList)? onDispose;
  final Widget? child;

  //
  //
  //

  const PodListBuilder({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.debounceDuration,
    this.child,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final temp = this.podList;
    if (temp is List<ValueListenable<T>>) {
      return _PodListBuilder(
        key: key,
        podList: temp,
        builder: builder,
        onDispose: onDispose,
        child: child,
      );
    } else {
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
          final data = snapshot.data?.nonNulls;
          if (data != null) {
            return _PodListBuilder(
              key: key,
              podList: data,
              builder: builder,
              onDispose: onDispose,
              child: child,
            );
          } else {
            final snapshot = PodListBuilderSnapshot<T>(
              podList: null,
              value: List<T?>.filled(temp.length, null),
              child: child,
            );
            final result = builder(context, snapshot);
            return result;
          }
        },
      );
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

@immutable
final class _PodListBuilder<T> extends StatefulWidget {
  //
  //
  //

  final TPodList<T> podList;
  final TOnValueBuilder<Iterable<T?>, PodListBuilderSnapshot<T>> builder;
  final void Function(Iterable<ValueListenable<T>> podList)? onDispose;
  final Duration? debounceDuration;
  final Widget? child;

  //
  //
  //

  const _PodListBuilder({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.debounceDuration,
    this.child,
  });

  //
  //
  //

  @override
  State<_PodListBuilder<T>> createState() => _PodListBuilderState();
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
      pod.addListener(_valueChanged!);
    }
  }

  //
  //
  //

  void _removeListenerFromPods(TPodList<T> pods) {
    for (final pod in pods) {
      pod.removeListener(_valueChanged!);
    }
  }

  //
  //
  //

  Timer? _debounceTimer;

  /// Allows initial data to be set immediately for responsiveness even if
  /// the debounce duration is long.
  bool _skipInitialDebounce = true;

  // ignore: prefer_final_fields
  late void Function()? _valueChanged = widget.debounceDuration != null
      ? () {
          if (_skipInitialDebounce) {
            _skipInitialDebounce = false;
            __valueChanged();
          } else {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(widget.debounceDuration!, () {
              __valueChanged();
            });
          }
        }
      : __valueChanged;

  @pragma('vm:prefer-inline')
  void __valueChanged() {
    if (mounted) {
      setState(() => _values = widget.podList.map((e) => e.value));
    }
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final snapshot = PodListBuilderSnapshot(
      podList: widget.podList,
      value: _values,
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
    for (final pod in widget.podList) {
      pod.removeListener(_valueChanged!);
    }
    _valueChanged = null;
    widget.onDispose?.call(widget.podList);
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodListBuilderSnapshot<T> extends OnValueSnapshot<Iterable<T?>> {
  //
  //
  //

  final Iterable<TFutureListenable<T>>? podList;

  //
  //
  //

  PodListBuilderSnapshot({
    required this.podList,
    required super.value,
    required super.child,
  });
}

typedef TPodList<T extends Object?> = Iterable<ValueListenable<T>>;

typedef TPodDataList<T extends Object?> = Iterable<T>;
