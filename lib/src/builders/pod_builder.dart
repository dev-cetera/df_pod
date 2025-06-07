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

final class PodBuilder<T extends Object> extends StatelessWidget {
  //
  //
  //

  final Resolvable<ValueListenable<T>> pod;
  final TOnOptionBuilder<T, PodBuilderOptionSnapshot<T>> builder;
  final void Function(ValueListenable<T> pod)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Widget? child;

  @protected
  static final cacheManager = CacheManager<Object>();

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
    this.child,
  }) : debounceDuration = Duration.zero;

  /// Constructs a [PodBuilder] with a short debounce duration of 100ms.
  const PodBuilder.short({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  }) : debounceDuration = const Duration(milliseconds: 100);

  /// Constructs a [PodBuilder] with a long debounce duration of 500ms.
  const PodBuilder.moderate({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  }) : debounceDuration = const Duration(milliseconds: 500);

  /// Constructs a [PodBuilder] with a long debounce duration of 1s.
  const PodBuilder.long({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  }) : debounceDuration = const Duration(seconds: 1);

  /// Constructs a [PodBuilder] with a long debounce duration of 3s.
  const PodBuilder.extraLong({
    super.key,
    required this.pod,
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
    if (pod.isSync()) {
      return SyncPodBuilder(
        key: key,
        pod: pod.unwrapSync().value,
        builder: (context, snapshot) {
          return builder(
            context,
            PodBuilderOptionSnapshot(
              pod: Some(snapshot.pod),
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
      return FutureBuilder(
        future: pod.unwrapAsync().value,
        builder: (context, snapshot) {
          final pod = snapshot.data;
          if (snapshot.hasData && pod != null) {
            return SyncPodBuilder(
              key: key,
              pod: pod,
              builder: (context, snapshot) {
                return builder(
                  context,
                  PodBuilderOptionSnapshot(
                    pod: Some(snapshot.pod),
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
            return builder(
              context,
              PodBuilderOptionSnapshot(
                pod: Option.fromNullable(pod),
                value: Option.fromNullable(
                  cacheManager.get(key?.toString()) as Result<T>?,
                ),
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

final class SyncPodBuilder<T extends Object> extends StatefulWidget {
  //
  //
  //

  final Result<ValueListenable<T>> pod;
  final TOnValueBuilder<T, PodBuilderValueSnapshot<T>> builder;
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

final class SyncPodBuilderState<T extends Object> extends State<SyncPodBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild;
  late Result<T> _value;

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _setValue();
    _cacheValue();
    widget.pod.ifOk((e) => e.unwrap().addListener(_valueChanged));
  }

  @override
  void didUpdateWidget(SyncPodBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pod != widget.pod) {
      oldWidget.pod.ifOk((e) => e.unwrap().removeListener(_valueChanged));
      _setValue();
      _cacheValue();
      widget.pod.ifOk((e) => e.unwrap().addListener(_valueChanged));
    }
  }

  void _setValue() {
    final key = widget.key;
    if (key != null) {
      final cachedValue = PodBuilder.cacheManager.get(key.toString()) as Result<T>?;
      if (cachedValue != null) {
        _value = cachedValue;
        return;
      }
    }

    _value = widget.pod.map((e) => e.value);
  }

  void _cacheValue() {
    final key = widget.key;
    if (key == null) {
      return;
    }
    PodBuilder.cacheManager.cache(
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      PodBuilderValueSnapshot(
        pod: widget.pod,
        value: _value,
        child: _staticChild,
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.pod.isOk()) {
      widget.pod.unwrap().removeListener(_valueChanged);
      widget.onDispose?.call(widget.pod.unwrap());
    } else {
      Log.err('Tried to dispose Err<ValueListenable<T>>!', {#df_pod});
    }
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodBuilderValueSnapshot<T extends Object> extends OnValueSnapshot<T> {
  final Result<ValueListenable<T>> pod;

  const PodBuilderValueSnapshot({
    required this.pod,
    required super.value,
    required super.child,
  });
}

final class PodBuilderOptionSnapshot<T extends Object> extends OnOptionSnapshot<T> {
  final Option<Result<ValueListenable<T>>> pod;

  const PodBuilderOptionSnapshot({
    required this.pod,
    required super.value,
    required super.child,
  });
}

typedef TOnValueBuilder<T extends Object, S extends OnValueSnapshot<T>> = Widget Function(
  BuildContext context,
  S snapshot,
);

class OnValueSnapshot<T extends Object> extends BuilderSnapshot {
  final Result<T> value;
  const OnValueSnapshot({required this.value, required super.child});
}

typedef TOnOptionBuilder<T extends Object, S extends OnOptionSnapshot<T>> = Widget Function(
  BuildContext context,
  S snapshot,
);

class OnOptionSnapshot<T extends Object> extends BuilderSnapshot {
  final Option<Result<T>> value;
  const OnOptionSnapshot({required this.value, required super.child});
}
