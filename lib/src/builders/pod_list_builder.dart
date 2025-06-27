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

import 'dart:async' show Timer, FutureOr;
import 'package:df_log/df_log.dart' show Log;
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class PodListBuilder<T extends Object> extends ResolvablePodListBuilder<T> {
  PodListBuilder({
    super.key,
    required Iterable<FutureOr<ValueListenable<T>>> podList,
    required super.builder,
    super.onDispose,
    super.debounceDuration,
    super.cacheDuration,
    super.child,
  }) : super(podList: podList.map((e) => Resolvable(() => e)));
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ResolvablePodListBuilder<T extends Object> extends StatelessWidget {
  //
  //
  //

  final Iterable<Resolvable<ValueListenable<T>>> podList;
  final TOnOptionListBuilder<T, PodListBuilderSnapshot<T>> builder;
  final void Function(Iterable<ValueListenable<T>> podList)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Widget? child;
  //
  //
  //

  const ResolvablePodListBuilder({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.debounceDuration,
    this.cacheDuration = Duration.zero,
    this.child,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final isSync = podList.every((e) => e.isSync());
    if (isSync) {
      return SyncPodListBuilder(
        key: key,
        podList: podList.map((e) => e.sync().unwrap()),
        builder: builder,
        onDispose: onDispose,
        debounceDuration: debounceDuration,
        cacheDuration: cacheDuration,
        child: child,
      );
    } else {
      return ForcedAsyncPodListBuilder(
        key: key,
        podList: podList,
        builder: builder,
        onDispose: onDispose,
        debounceDuration: debounceDuration,
        cacheDuration: cacheDuration,
        child: child,
      );
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class SyncPodListBuilder<T extends Object> extends StatelessWidget {
  //
  //
  //

  final Iterable<Sync<ValueListenable<T>>> podList;
  final TOnOptionListBuilder<T, PodListBuilderSnapshot<T>> builder;
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
    this.cacheDuration = Duration.zero,
    this.child,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return PodResultListBuilder(
      key: key,
      podList: podList.map((e) => e.sync().unwrap().value),
      builder: builder,
      onDispose: onDispose,
      cacheDuration: cacheDuration,
      debounceDuration: debounceDuration,
      child: child,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ForcedAsyncPodListBuilder<T extends Object> extends StatelessWidget {
  //
  //
  //

  final Iterable<Resolvable<ValueListenable<T>>> podList;
  final TOnOptionListBuilder<T, PodListBuilderSnapshot<T>> builder;
  final void Function(Iterable<ValueListenable<T>> podList)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Widget? child;

  //
  //
  //

  const ForcedAsyncPodListBuilder({
    super.key,
    required this.podList,
    required this.builder,
    this.onDispose,
    this.debounceDuration,
    this.cacheDuration = Duration.zero,
    this.child,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: () async {
        return await Future.wait(
          podList.map((e) => e.toAsync().value).map(
                (e) => () async {
                  return e;
                }(),
              ),
        );
      }(),
      builder: (context, snapshot) {
        final podList = snapshot.data;
        if (snapshot.hasData && podList != null) {
          return PodResultListBuilder(
            key: key,
            podList: podList,
            builder: builder,
            onDispose: onDispose,
            cacheDuration: cacheDuration,
            debounceDuration: debounceDuration,
            child: child,
          );
        } else {
          final snapshot = PodListBuilderSnapshot<T>(
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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodResultListBuilder<T extends Object> extends StatefulWidget {
  //
  //
  //

  final Iterable<Result<ValueListenable<T>>> podList;
  final TOnOptionListBuilder<T, PodListBuilderSnapshot<T>> builder;
  final void Function(Iterable<ValueListenable<T>> podList)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Widget? child;

  //
  //
  //

  const PodResultListBuilder({
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
  State<PodResultListBuilder<T>> createState() => PodResultListBuilderState();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodResultListBuilderState<T extends Object> extends State<PodResultListBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild;
  late Iterable<Result<T>> _valueList;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _setValue();
    _cacheValue();
    _addListenerToPods(widget.podList);
  }

  //
  //
  //

  @override
  void didUpdateWidget(PodResultListBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _removeListenerFromPods(oldWidget.podList);
    _setValue();
    _cacheValue();
    _addListenerToPods(widget.podList);
  }

  //
  //
  //

  void _setValue() {
    final key = widget.key;
    if (key != null) {
      final cachedValue =
          PodBuilderCacheManager.i.cacheManager.get(key.toString()) as Iterable<Result<T>>?;
      if (cachedValue != null) {
        _valueList = cachedValue;
        return;
      }
    }
    _valueList = widget.podList.map((e) => e.map((e) => e.value));
  }

  //
  //
  //

  void _cacheValue() {
    final key = widget.key;
    if (key == null) {
      return;
    }
    PodBuilderCacheManager.i.cacheManager.cache(
      key.toString(),
      widget.podList.map((e) => e.map((e) => e.value)),
      cacheDuration: widget.cacheDuration,
    );
  }

  //
  //
  //

  void _addListenerToPods(Iterable<Result<ValueListenable<T>>> pods) {
    for (final pod in pods) {
      if (pod.isErr()) continue;
      pod.unwrap().addListener(_valueChanged);
    }
  }

  //
  //
  //

  void _removeListenerFromPods(Iterable<Result<ValueListenable<T>>> pods) {
    for (final pod in pods) {
      if (pod.isErr()) continue;
      pod.unwrap().removeListener(_valueChanged);
    }
  }

  //
  //
  //

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

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      PodListBuilderSnapshot(
        podList: Some(widget.podList),
        value: Some(_valueList.map((e) => Some(e))),
        child: _staticChild,
      ),
    );
  }

  //
  //
  //

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

final class PodListBuilderSnapshot<T extends Object> extends OnOptionListSnapshot<T> {
  final Option<Iterable<Result<ValueListenable<T>>>> podList;

  const PodListBuilderSnapshot({
    required this.podList,
    required super.value,
    required super.child,
  });
}

typedef TOnOptionListBuilder<T extends Object, TSnapshot extends OnOptionListSnapshot<T>> = Widget
    Function(BuildContext context, TSnapshot snapshot);

class OnOptionListSnapshot<T extends Object> extends BuilderSnapshot {
  final Option<Iterable<Option<Result<T>>>> value;
  const OnOptionListSnapshot({required this.value, required super.child});

  Option<Iterable<Option<Result<R>>>> reduce<R extends Object>() {
    return value.map(
      (e) => e.map((e) {
        final reduced = e.reduce<R>();
        if (reduced.isAsync()) {
          return const None();
        }
        return reduced.sync().unwrap().value.swap();
      }),
    );
  }
}
