//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Copyright © dev-cetera.com & contributors.
//
// The use of this source code is governed by an MIT-style license described in
// the LICENSE file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class PollingPodBuilder<T extends Object>
    extends ResolvablePollingPodBuilder<T> {
  PollingPodBuilder({
    super.key,
    // ignore: df_safer_dart_lints/no_future_outcome_type_or_error
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
  State<ResolvablePollingPodBuilder<T>> createState() =>
      _ResolvablePollingPodBuilderState<T>();
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
    // Use `identical` for the poller closure: function `==` is identity, so
    // an inline `() => ...` produces a new object on every parent rebuild
    // and would tear the timer down and back up unnecessarily. Callers that
    // truly want a different poller should pass a different reference.
    if (!identical(oldWidget.podPoller, widget.podPoller) ||
        oldWidget.interval != widget.interval) {
      _maybeStartPolling();
    }
  }

  void _maybeStartPolling() {
    if (!_check()) {
      _startPolling();
    }
  }

  void _startPolling() {
    final interval = widget.interval;
    if (interval == null) return;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) {
      if (_check()) {
        _pollingTimer?.cancel();
      }
    });
  }

  /// Runs the user-supplied poller and (if it returned `Some`) schedules
  /// a rebuild. Returns true when polling should stop.
  ///
  /// All exceptions from [widget.podPoller] are caught and logged. Without
  /// this, a throwing poller would propagate out of the [Timer.periodic]
  /// callback, leaving the timer alive but throwing on *every* tick —
  /// unbounded log spam and CPU on long-running deployments. The timer is
  /// kept running on poller failure because the failure may be transient
  /// (e.g. DI scope not yet initialized).
  bool _check() {
    try {
      _currentPod = widget.podPoller();
    } catch (e, s) {
      Log.err(e, tags: {#df_pod});
      // Re-log with stack so the failure is debuggable. Keep polling.
      assert(() {
        debugPrint('PollingPodBuilder poller threw: $e\n$s');
        return true;
      }());
      return false;
    }
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
            PodBuilderCacheManager.i.get(widget.key?.toString()) as Result<T>?,
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
