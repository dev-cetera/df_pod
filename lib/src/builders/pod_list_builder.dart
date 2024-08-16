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

class PodListBuilder<T> extends StatelessWidget {
  //
  //
  //

  final Iterable<FutureOr<PodListenable<T>>> podList;

  //
  //
  //

  final TOnValueBuilder<Iterable<T?>, PodListBuilderSnapshot<T>> builder;

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
          final params = PodListBuilderSnapshot<T>(
            podList: null,
            context: context,
            value: List<T?>.filled(temp.length, null),
            child: child,
          );
          return builder(params);
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

  final TOnValueBuilder<Iterable<T?>, PodListBuilderSnapshot<T>> builder;

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
    final params = PodListBuilderSnapshot(
      podList: widget.podList,
      context: context,
      value: _values,
      child: _staticChild,
    );
    return widget.builder(params);
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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodListBuilderSnapshot<T> extends OnValueSnapshot<Iterable<T?>> {
  //
  //
  //

  final Iterable<FutureOr<PodListenable<T>>>? podList;

  //
  //
  //

  PodListBuilderSnapshot({
    required this.podList,
    required super.context,
    required super.value,
    required super.child,
  });
}

typedef TPodList<T extends Object?> = Iterable<PodListenable<T>>;

typedef TPodDataList<T extends Object?> = Iterable<T>;
