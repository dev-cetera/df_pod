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

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class PollingPodBuilder<T extends Object> extends ResolvablePollingPodBuilder<T> {
  PollingPodBuilder({
    super.key,
    // ignore: no_future_outcome_type_or_error
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
  final TOnOptionBuilder<T, PodBuilderSnapshot<T>> builder;
  final void Function(ValueListenable<T>? pod)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Duration? interval;
  final Widget? child;

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
    required this.interval,
    this.child,
  });

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
      UNSAFE:
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
        PodBuilderSnapshot<T>(
          pod: const None(),
          value: Option.from(
            PodBuilderCacheManager.i.cacheManager.get(widget.key?.toString()) as Result<T>?,
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
