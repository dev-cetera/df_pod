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

class PodListCallbackBuilder extends StatefulWidget {
  //
  //
  //

  final TPodListCallbackN listCallback;

  //
  //
  //

  final TOnValueBuilder<Iterable<dynamic>, PodListCallbackBuilderSnapshot>
      builder;

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

  const PodListCallbackBuilder({
    super.key,
    required this.listCallback,
    required this.builder,
    this.child,
    this.onDispose,
  });

  //
  //
  //

  @override
  State<PodListCallbackBuilder> createState() => _PodListCallbackBuilderState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodListCallbackBuilderState extends State<PodListCallbackBuilder> {
  //
  //
  //

  late final Widget? _staticChild;
  TPodListN _currentPods = {};

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _refreshCurrentPods();
  }

  //
  //
  //

  @override
  void didUpdateWidget(PodListCallbackBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listCallback != widget.listCallback) {
      _removeListenersFromCurrentPods();
      _refreshCurrentPods();
    }
  }

  //
  //
  //

  void _valueChanged() {
    _removeListenersFromCurrentPods();
    _refreshCurrentPods();
    if (mounted) {
      setState(() {});
    }
  }

  //
  //
  //

  void _refreshCurrentPods() {
    _currentPods = widget.listCallback();
    _addListenersToCurrentPods();
  }

  //
  //
  //

  void _addListenersToCurrentPods() {
    for (final pod in _currentPods) {
      pod?.addListener(_valueChanged);
    }
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final values = _currentPods.map((pod) => pod?.value);
    final snapshot = PodListCallbackBuilderSnapshot(
      podList: _currentPods,
      value: values,
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
    _removeListenersFromCurrentPods();
    widget.onDispose?.call();
    super.dispose();
  }

  //
  //
  //

  void _removeListenersFromCurrentPods() {
    for (final pod in _currentPods) {
      pod?.removeListener(_valueChanged);
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodListCallbackBuilderSnapshot
    extends OnValueSnapshot<TPodDataListN> {
  //
  //
  //

  final TPodListN? podList;

  //
  //
  //

  PodListCallbackBuilderSnapshot({
    required this.podList,
    required super.value,
    required super.child,
  });
}

typedef TPodListN<T extends Object?> = Iterable<PodListenable<T?>?>;

typedef TPodDataListN<T extends Object?> = Iterable<T?>;

typedef TPodListCallbackN<T extends Object?> = TPodListN<T> Function();
