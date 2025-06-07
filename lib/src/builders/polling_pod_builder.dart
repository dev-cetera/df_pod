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
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:df_debouncer/df_debouncer.dart' show CacheManager;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '/src/_src.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class PollingPodBuilder<T extends Object> extends ResolvablePollingPodBuilder<T> {
  PollingPodBuilder({
    super.key,
    required Option<FutureOr<ValueListenable<T>>> Function() podPoller,
    required super.builder,
    super.onDispose,
    super.debounceDuration,
    super.cacheDuration,
    super.interval,
    super.child,
  }) : super(podPoller: () => podPoller().map((e) => Resolvable(() => e)));
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ResolvablePollingPodBuilder<T extends Object> extends StatefulWidget {
  //
  //
  //

  final Option<Resolvable<ValueListenable<T>>> Function() podPoller;
  final TOnOptionBuilder<T, PodBuilderOptionSnapshot<T>> builder;
  final void Function(ValueListenable<T>? pod)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Duration? interval;
  final Widget? child;

  @protected
  static final cacheManager = CacheManager<Object>();

  //
  //
  //

  const ResolvablePollingPodBuilder({
    super.key,
    required this.podPoller,
    required this.builder,
    this.onDispose,
    this.debounceDuration,
    this.cacheDuration = Duration.zero,
    this.interval = Duration.zero,
    this.child,
  });

  /// Constructs a [ResolvablePollingPodBuilder] with zero interval and zero debounce
  /// duration
  @visibleForTesting
  const ResolvablePollingPodBuilder.immediate({
    super.key,
    required this.podPoller,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  })  : interval = Duration.zero,
        debounceDuration = Duration.zero;

  /// Constructs a [ResolvablePollingPodBuilder] with a short polling interval of 100ms
  /// and debounce duration of 100ms.
  const ResolvablePollingPodBuilder.short({
    super.key,
    required this.podPoller,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  })  : interval = const Duration(milliseconds: 100),
        debounceDuration = const Duration(milliseconds: 100);

  /// Constructs a [ResolvablePollingPodBuilder] with a long polling interval of 500ms
  /// and debounce duration of 500ms.
  const ResolvablePollingPodBuilder.moderate({
    super.key,
    required this.podPoller,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  })  : interval = const Duration(milliseconds: 500),
        debounceDuration = const Duration(milliseconds: 500);

  /// Constructs a [ResolvablePollingPodBuilder] with a long polling interval of 1s and
  /// debounce duration of 1s.
  const ResolvablePollingPodBuilder.long({
    super.key,
    required this.podPoller,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  })  : interval = const Duration(seconds: 1),
        debounceDuration = const Duration(seconds: 1);

  /// Constructs a [ResolvablePollingPodBuilder] with a long polling interval of 3s
  /// and debounce duration of 3s.
  const ResolvablePollingPodBuilder.extraLong({
    super.key,
    required this.podPoller,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  })  : interval = const Duration(seconds: 3),
        debounceDuration = const Duration(seconds: 13);

  //
  //
  //

  @override
  State<ResolvablePollingPodBuilder<T>> createState() => _ResolvablePollingPodBuilderState<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class _ResolvablePollingPodBuilderState<T extends Object>
    extends State<ResolvablePollingPodBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild = widget.child;
  Option<Resolvable<ValueListenable<T>>> _currentPod = const None();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _maybeStartPolling();
  }

  @override
  void didUpdateWidget(ResolvablePollingPodBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.podPoller != widget.podPoller || oldWidget.interval != widget.interval) {
      _maybeStartPolling();
    }
  }

  void _maybeStartPolling() {
    if (!_check()) {
      _startPolling();
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(widget.interval!, (_) {
      if (_check()) {
        _pollingTimer?.cancel();
      }
    });
  }

  bool _check() {
    _currentPod = widget.podPoller();
    if (_currentPod.isSome()) {
      if (mounted) {
        setState(() {});
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPod.isSome()) {
      return ResolvablePodBuilder<T>(
        key: widget.key,
        pod: _currentPod.unwrap(),
        builder: widget.builder,
        onDispose: widget.onDispose,
        debounceDuration: widget.debounceDuration,
        cacheDuration: widget.cacheDuration,
        child: _staticChild,
      );
    } else {
      final result = widget.builder(
        context,
        PodBuilderOptionSnapshot<T>(
          pod: const None(),
          value: Option.fromNullable(
            ResolvablePollingPodBuilder.cacheManager.get(widget.key?.toString()) as Result<T>?,
          ),
          child: _staticChild,
        ),
      );
      return result;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
