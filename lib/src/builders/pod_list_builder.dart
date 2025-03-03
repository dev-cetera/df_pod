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
import 'package:df_debouncer/df_debouncer.dart' show CacheManager;
import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodListBuilder<T> extends StatelessWidget {
  //
  //
  //

  final Iterable<TFutureListenable<T>> podList;
  final TOnValueBuilder<Iterable<T?>, PodListBuilderSnapshot<T>> builder;
  final void Function(Iterable<ValueListenable<T>> podList)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;

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
    this.cacheDuration = Duration.zero,
    this.child,
  });

  /// Constructs a [PodListBuilder] with a zero debounce duration.
  @visibleForTesting
  const PodListBuilder.immediate({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  }) : debounceDuration = Duration.zero;

  /// Constructs a [PodListBuilder] with a short debounce duration of 100ms.
  const PodListBuilder.short({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  }) : debounceDuration = const Duration(milliseconds: 100);

  /// Constructs a [PodListBuilder] with a long debounce duration of 500ms.
  const PodListBuilder.moderate({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  }) : debounceDuration = const Duration(milliseconds: 500);

  /// Constructs a [PodListBuilder] with a long debounce duration of 1s.
  const PodListBuilder.long({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  }) : debounceDuration = const Duration(seconds: 1);

  /// Constructs a [PodListBuilder] with a long debounce duration of 3s.
  const PodListBuilder.extraLong({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  }) : debounceDuration = const Duration(seconds: 3);

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final temp = this.podList;
    if (temp is List<ValueListenable<T>>) {
      return SyncPodListBuilder(
        key: key,
        podList: temp,
        builder: builder,
        onDispose: onDispose,
        cacheDuration: cacheDuration,
        debounceDuration: debounceDuration,
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
            return SyncPodListBuilder(
              key: key,
              podList: data,
              builder: builder,
              onDispose: onDispose,
              cacheDuration: cacheDuration,
              debounceDuration: debounceDuration,
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

final class SyncPodListBuilder<T> extends StatefulWidget {
  //
  //
  //

  final TPodList<T> podList;
  final TOnValueBuilder<Iterable<T?>, PodListBuilderSnapshot<T>> builder;
  final void Function(Iterable<ValueListenable<T>> podList)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Widget? child;

  //
  //
  //

  const SyncPodListBuilder({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.debounceDuration,
    required this.cacheDuration,
    this.child,
  });

  //
  //
  //

  @override
  State<SyncPodListBuilder<T>> createState() => SyncPodListBuilderState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SyncPodListBuilderState<T> extends State<SyncPodListBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild;
  late Iterable<T> _values;

  @protected
  static final cacheManager = CacheManager<Iterable<dynamic>>();

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _setValue();
    _cacheValue();
    _refresh();
    _addListenerToPods(widget.podList);
  }

  @override
  void didUpdateWidget(SyncPodListBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_arePodListsEqual(widget.podList, oldWidget.podList)) {
      _removeListenerFromPods(oldWidget.podList);
      _setValue();
      _cacheValue();
      _addListenerToPods(widget.podList);
    }
  }

  bool _arePodListsEqual(TPodList<T> a, TPodList<T> b) {
    if (identical(a, b)) return true;
    final aIter = a.iterator;
    final bIter = b.iterator;
    while (aIter.moveNext()) {
      if (!bIter.moveNext() || aIter.current != bIter.current) return false;
    }
    return !bIter.moveNext();
  }

  void _setValue() {
    final values = widget.podList.map((e) => e.value);
    final key = widget.key;
    if (key != null && values.isEmpty) {
      _values = cacheManager.get(key.toString())?.map((e) => e as T) ?? [];
    } else {
      _values = values;
    }
  }

  void _cacheValue() {
    final key = widget.key;
    if (key == null) {
      return;
    }
    cacheManager.cache(
      key.toString(),
      widget.podList.map((e) => e.value),
      cacheDuration: widget.cacheDuration,
    );
  }

  void _addListenerToPods(TPodList<T> pods) {
    for (final pod in pods) {
      pod.addListener(_valueChanged);
    }
  }

  void _removeListenerFromPods(TPodList<T> pods) {
    for (final pod in pods) {
      pod.removeListener(_valueChanged);
    }
  }

  Timer? _debounceTimer;

  // ignore: prefer_final_fields
  late void Function() _valueChanged =
      widget.debounceDuration != null
          ? () {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(widget.debounceDuration!, () {
              __valueChanged();
            });
          }
          : __valueChanged;

  void __valueChanged() {
    if (mounted) {
      setState(() {
        _setValue();
        _cacheValue();
        _refresh();
      });
    }
  }

  void _refresh() {
    final snapshot = PodListBuilderSnapshot(
      podList: widget.podList,
      value: _values,
      child: _staticChild,
    );
    _temp = Builder(
      builder: (context) {
        return widget.builder(context, snapshot);
      },
    );
  }

  late Widget _temp;

  @override
  Widget build(BuildContext context) {
    return _temp;
  }

  @override
  void dispose() {
    for (final pod in widget.podList) {
      pod.removeListener(_valueChanged);
    }
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
