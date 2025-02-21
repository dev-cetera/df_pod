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

import 'package:flutter/foundation.dart' show ValueListenable;

import 'package:flutter/widgets.dart';

import '/src/_index.g.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PollingPodBuilder<T> extends StatefulWidget {
  //
  //
  //

  final TFutureListenable<T>? Function() podPoller;
  final TOnValueBuilder<T?, PodBuilderSnapshot<T>> builder;
  final void Function(ValueListenable<T>? pod)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Duration? interval;
  final Widget? child;

  //
  //
  //

  const PollingPodBuilder({
    super.key,
    required this.podPoller,
    required this.builder,
    this.onDispose,
    this.debounceDuration,
    this.cacheDuration = Duration.zero,
    this.interval = Duration.zero,
    this.child,
  });

  /// Constructs a [PollingPodBuilder] with zero interval and zero debounce
  /// duration
  @visibleForTesting
  const PollingPodBuilder.immediate({
    super.key,
    required this.podPoller,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  })  : interval = Duration.zero,
        debounceDuration = Duration.zero;

  /// Constructs a [PollingPodBuilder] with a short polling interval of 100ms
  /// and debounce duration of 100ms.
  const PollingPodBuilder.short({
    super.key,
    required this.podPoller,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  })  : interval = const Duration(milliseconds: 100),
        debounceDuration = const Duration(milliseconds: 100);

  /// Constructs a [PollingPodBuilder] with a long polling interval of 500ms
  /// and debounce duration of 500ms.
  const PollingPodBuilder.long({
    super.key,
    required this.podPoller,
    required this.builder,
    this.onDispose,
    this.cacheDuration = Duration.zero,
    this.child,
  })  : interval = const Duration(milliseconds: 500),
        debounceDuration = const Duration(milliseconds: 500);

  //
  //
  //

  @override
  State<PollingPodBuilder<T>> createState() => _PollingPodBuilderState<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class _PollingPodBuilderState<T> extends State<PollingPodBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild = widget.child;
  TFutureListenable<T>? _currentPod;
  Timer? _pollingTimer;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _maybeStartPolling();
  }

  //
  //
  //

  @override
  void didUpdateWidget(PollingPodBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.podPoller != widget.podPoller || oldWidget.interval != widget.interval) {
      _maybeStartPolling();
    }
  }

  //
  //
  //

  void _maybeStartPolling() {
    if (!_check()) {
      _startPolling();
    }
  }

  //
  //
  //

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(widget.interval!, (_) {
      if (_check()) {
        _pollingTimer?.cancel();
      }
    });
  }

  //
  //
  //

  bool _check() {
    _currentPod = widget.podPoller();
    if (_currentPod != null) {
      if (mounted) {
        setState(() {});
        return true;
      }
    }
    return false;
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    if (_currentPod != null) {
      return PodBuilder<T>(
        key: widget.key,
        pod: _currentPod!,
        builder: widget.builder,
        onDispose: widget.onDispose,
        debounceDuration: widget.debounceDuration,
        cacheDuration: widget.cacheDuration,
        child: _staticChild,
      );
    } else {
      final snapshot = PodBuilderSnapshot<T>(
        pod: null,
        // ignore: invalid_use_of_protected_member
        value: SyncPodBuilderState.cacheManager.get(widget.key?.toString()) as T?,
        child: _staticChild,
      );
      final result = widget.builder(context, snapshot);
      return result;
    }
  }

  //
  //
  //

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
