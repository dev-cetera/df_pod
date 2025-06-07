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

import 'dart:async' show Timer;
import 'package:df_log/df_log.dart' show Log;
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:df_debouncer/df_debouncer.dart' show CacheManager;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodListBuilder<T extends Object> extends StatelessWidget {
  //
  //
  //

  final Iterable<Resolvable<ValueListenable<T>>> podList;
  final TOnOptionListBuilder<T, PodListBuilderOptionSnapshot<T>> builder;
  final void Function(Iterable<ValueListenable<T>> podList)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Iterable<T>? fallback;
  final Widget? child;

  @protected
  static final cacheManager = CacheManager<Iterable<Object>>();

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
    this.fallback,
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
    this.fallback,
  }) : debounceDuration = Duration.zero;

  /// Constructs a [PodListBuilder] with a short debounce duration of 100ms.
  const PodListBuilder.short({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
    this.fallback,
  }) : debounceDuration = const Duration(milliseconds: 100);

  /// Constructs a [PodListBuilder] with a long debounce duration of 500ms.
  const PodListBuilder.moderate({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
    this.fallback,
  }) : debounceDuration = const Duration(milliseconds: 500);

  /// Constructs a [PodListBuilder] with a long debounce duration of 1s.
  const PodListBuilder.long({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
    this.fallback,
  }) : debounceDuration = const Duration(seconds: 1);

  /// Constructs a [PodListBuilder] with a long debounce duration of 3s.
  const PodListBuilder.extraLong({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
    this.fallback,
  }) : debounceDuration = const Duration(seconds: 3);

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final isSync = podList.every((e) => e.isSync());
    if (isSync) {
      final podList1 = podList.map((e) => e.unwrapSync().value);
      return SyncPodListBuilder(
        key: key,
        podList: podList1,
        builder: (context, snapshot) {
          return builder(
            context,
            PodListBuilderOptionSnapshot(
              podList: Some(podList1),
              value: Some(snapshot.value),
              child: child,
            ),
          );
        },
        onDispose: onDispose,
        cacheDuration: cacheDuration,
        debounceDuration: debounceDuration,
        child: child,
      );
    } else {
      final podList2 = podList.map((e) => e.asAsync().value);
      return FutureBuilder(
        future: () async {
          return await Future.wait(
            podList2.map(
              (e) => () async {
                return e;
              }(),
            ),
          );
        }(),
        builder: (context, snapshot) {
          final podList = snapshot.data;
          if (snapshot.hasData && podList != null) {
            return SyncPodListBuilder(
              key: key,
              podList: podList,
              builder: (context, snapshot) {
                return builder(
                  context,
                  PodListBuilderOptionSnapshot(
                    podList: Some(podList),
                    value: Some(snapshot.value),
                    child: child,
                  ),
                );
              },
              onDispose: onDispose,
              cacheDuration: cacheDuration,
              debounceDuration: debounceDuration,
              child: child,
            );
          } else {
            final snapshot = PodListBuilderOptionSnapshot<T>(
              podList: const None(),
              value: const None(),
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

final class SyncPodListBuilder<T extends Object> extends StatefulWidget {
  //
  //
  //

  final Iterable<Result<ValueListenable<T>>> podList;
  final TOnValueListBuilder<T, PodListBuilderValueSnapshot<T>> builder;
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

final class SyncPodListBuilderState<T extends Object> extends State<SyncPodListBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild;
  late Iterable<Result<T>> _valueList;

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _setValue();
    _cacheValue();
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

  bool _arePodListsEqual(
    Iterable<Result<ValueListenable<T>>> a,
    Iterable<Result<ValueListenable<T>>> b,
  ) {
    if (identical(a, b)) return true;
    final aIter = a.iterator;
    final bIter = b.iterator;
    while (aIter.moveNext()) {
      if (!bIter.moveNext() || aIter.current != bIter.current) return false;
    }
    return !bIter.moveNext();
  }

  void _setValue() {
    final key = widget.key;
    if (key != null) {
      final cachedValue = PodListBuilder.cacheManager.get(key.toString()) as Iterable<Result<T>>?;
      if (cachedValue != null) {
        _valueList = cachedValue;
        return;
      }
    }
    _valueList = widget.podList.map((e) => e.map((e) => e.value));
  }

  void _cacheValue() {
    final key = widget.key;
    if (key == null) {
      return;
    }
    PodListBuilder.cacheManager.cache(
      key.toString(),
      widget.podList.map((e) => e.map((e) => e.value)),
      cacheDuration: widget.cacheDuration,
    );
  }

  void _addListenerToPods(Iterable<Result<ValueListenable<T>>> pods) {
    for (final pod in pods) {
      if (pod.isErr()) continue;
      pod.unwrap().addListener(_valueChanged);
    }
  }

  void _removeListenerFromPods(Iterable<Result<ValueListenable<T>>> pods) {
    for (final pod in pods) {
      if (pod.isErr()) continue;
      pod.unwrap().removeListener(_valueChanged);
    }
  }

  Timer? _debounceTimer;

  // ignore: prefer_final_fields
  late void Function() _valueChanged = widget.debounceDuration != null
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      PodListBuilderValueSnapshot(
        podList: widget.podList,
        value: _valueList,
        child: _staticChild,
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    final temp = <ValueListenable<T>>[];
    for (final pod in widget.podList) {
      if (pod.isErr()) {
        Log.err('Tried to dispose Err<ValueListenable<T>>!', {#df_pod});
        continue;
      }
      pod.unwrap().removeListener(_valueChanged);
      temp.add(pod.unwrap());
    }
    widget.onDispose?.call(temp);
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodListBuilderValueSnapshot<T extends Object> extends OnValueListSnapshot<T> {
  final Iterable<Result<ValueListenable<T>>> podList;

  const PodListBuilderValueSnapshot({
    required this.podList,
    required super.value,
    required super.child,
  });
}

final class PodListBuilderOptionSnapshot<T extends Object> extends OnOptionListSnapshot<T> {
  final Option<Iterable<Result<ValueListenable<T>>>> podList;

  const PodListBuilderOptionSnapshot({
    required this.podList,
    required super.value,
    required super.child,
  });
}

typedef TOnValueListBuilder<T extends Object, S extends OnValueListSnapshot<T>> = Widget Function(
  BuildContext context,
  S snapshot,
);

class OnValueListSnapshot<T extends Object> extends BuilderSnapshot {
  final Iterable<Result<T>> value;
  const OnValueListSnapshot({required this.value, required super.child});
}

typedef TOnOptionListBuilder<T extends Object, S extends OnOptionListSnapshot<T>> = Widget Function(
  BuildContext context,
  S snapshot,
);

class OnOptionListSnapshot<T extends Object> extends BuilderSnapshot {
  final Option<Iterable<Result<T>>> value;
  const OnOptionListSnapshot({required this.value, required super.child});
}
