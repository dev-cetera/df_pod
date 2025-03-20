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
import 'package:df_type/df_type.dart' show isNullable;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:df_debouncer/df_debouncer.dart' show CacheManager;

import 'package:flutter/widgets.dart';
import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodBuilder<T> extends StatelessWidget {
  //
  //
  //

  final TFutureListenable<T> pod;
  final TOnValueBuilder<T?, PodBuilderSnapshot<T>> builder;
  final void Function(ValueListenable<T> pod)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final T? fallback;
  final Widget? child;

  //
  //
  //

  const PodBuilder({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.debounceDuration,
    this.cacheDuration = Duration.zero,
    this.fallback,
    this.child,
  });

  // Constructs a [PodBuilder] with a zero debounce duration.
  @visibleForTesting
  const PodBuilder.immediate({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.fallback,
    this.child,
  }) : debounceDuration = Duration.zero;

  /// Constructs a [PodBuilder] with a short debounce duration of 100ms.
  const PodBuilder.short({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.fallback,
    this.child,
  }) : debounceDuration = const Duration(milliseconds: 100);

  /// Constructs a [PodBuilder] with a long debounce duration of 500ms.
  const PodBuilder.moderate({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.fallback,
    this.child,
  }) : debounceDuration = const Duration(milliseconds: 500);

  /// Constructs a [PodBuilder] with a long debounce duration of 51s.
  const PodBuilder.long({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.fallback,
    this.child,
  }) : debounceDuration = const Duration(seconds: 1);

  /// Constructs a [PodBuilder] with a long debounce duration of 3s.
  const PodBuilder.extraLong({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.fallback,
    this.child,
  }) : debounceDuration = const Duration(seconds: 3);

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final temp = pod;
    if (temp is ValueListenable<T>) {
      return SyncPodBuilder(
        key: key,
        pod: temp,
        builder: builder,
        onDispose: onDispose,
        cacheDuration: cacheDuration,
        debounceDuration: debounceDuration,
        child: child,
      );
    } else {
      return FutureBuilder(
        future: temp as Future<ValueListenable<T>?>,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data != null) {
            return SyncPodBuilder(
              key: key,
              pod: data,
              builder: builder,
              onDispose: onDispose,
              cacheDuration: cacheDuration,
              debounceDuration: debounceDuration,
              child: child,
            );
          } else {
            return builder(
              context,
              PodBuilderSnapshot<T>(
                pod: null,
                value: fallback,
                child: child,
              ),
            );
          }
        },
      );
    }
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SyncPodBuilder<T> extends StatefulWidget {
  //
  //
  //

  final ValueListenable<T> pod;
  final TOnValueBuilder<T?, PodBuilderSnapshot<T>> builder;
  final void Function(ValueListenable<T> pod)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Widget? child;

  //
  //
  //

  const SyncPodBuilder({
    super.key,
    required this.pod,
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
  State<SyncPodBuilder<T>> createState() => SyncPodBuilderState<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class SyncPodBuilderState<T> extends State<SyncPodBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild;
  late T _value;

  @protected
  static final cacheManager = CacheManager<dynamic>();

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _setValue();
    _cacheValue();
    _refresh();
    widget.pod.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(SyncPodBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pod != widget.pod) {
      oldWidget.pod.removeListener(_valueChanged);
      _setValue();
      _cacheValue();
      widget.pod.addListener(_valueChanged);
    }
  }

  void _setValue() {
    final key = widget.key;
    _value = key != null && isNullable<T>()
        ? cacheManager.get(key.toString()) as T? ?? widget.pod.value
        : widget.pod.value;
  }

  void _cacheValue() {
    final key = widget.key;
    if (key == null) {
      return;
    }
    cacheManager.cache(
      key.toString(),
      _value,
      cacheDuration: widget.cacheDuration,
    );
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
        _refresh();
      });
    }
  }

  void _refresh() {
    final snapshot = PodBuilderSnapshot(
      pod: widget.pod,
      value: _value,
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
    _debounceTimer?.cancel();
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

  final ValueListenable<T>? pod;

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
