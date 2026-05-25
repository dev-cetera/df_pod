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

class PodBuilder<T extends Object> extends ResolvablePodBuilder<T> {
  PodBuilder({
    super.key,
    required FutureOr<ValueListenable<T>> pod,
    required super.builder,
    super.onDispose,
    super.debounceDuration,
    super.cacheDuration,
    super.child,
  }) : super(pod: Resolvable(() => pod));
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ResolvablePodBuilder<T extends Object> extends StatelessWidget {
  //
  //
  //

  final Resolvable<ValueListenable<T>> pod;
  final TOnOptionBuilder<T, PodBuilderSnapshot<T>> builder;
  final void Function(ValueListenable<T> pod)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Widget? child;

  //
  //
  //

  const ResolvablePodBuilder({
    super.key,
    required this.pod,
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
    UNSAFE:
    if (pod.isSync()) {
      return SyncPodBuilder(
        key: key,
        pod: pod.sync().unwrap(),
        builder: builder,
        onDispose: onDispose,
        debounceDuration: debounceDuration,
        cacheDuration: cacheDuration,
        child: child,
      );
    } else {
      return AsyncPodBuilder(
        key: key,
        pod: pod.async().unwrap(),
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

class SyncPodBuilder<T extends Object> extends StatelessWidget {
  //
  //
  //

  final Sync<ValueListenable<T>> pod;
  final TOnOptionBuilder<T, PodBuilderSnapshot<T>> builder;
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
    this.cacheDuration = Duration.zero,
    this.child,
  });

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    return PodResultBuilder(
      key: key,
      pod: pod.value,
      builder: builder,
      onDispose: onDispose,
      cacheDuration: cacheDuration,
      debounceDuration: debounceDuration,
      child: child,
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class AsyncPodBuilder<T extends Object> extends StatelessWidget {
  //
  //
  //

  final Async<ValueListenable<T>> pod;
  final TOnOptionBuilder<T, PodBuilderSnapshot<T>> builder;
  final void Function(ValueListenable<T> pod)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Widget? child;

  //
  //
  //

  const AsyncPodBuilder({
    super.key,
    required this.pod,
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
      future: pod.value,
      builder: (context, snapshot) {
        final pod = snapshot.data;
        if (snapshot.hasData && pod != null) {
          return PodResultBuilder(
            key: key,
            pod: pod,
            builder: builder,
            onDispose: onDispose,
            cacheDuration: cacheDuration,
            debounceDuration: debounceDuration,
            child: child,
          );
        } else {
          final cached = PodBuilderCacheManager.i.get(key?.toString());
          // Surface pod-creation errors so the builder can render an error
          // state instead of an indistinguishable "still loading" state.
          // Earlier the FutureBuilder error path was silently mapped to
          // `pod: None`, which is the same shape as the loading state —
          // critical for medical-grade callers that need to escalate a
          // failed lookup rather than spin forever.
          final Option<Result<ValueListenable<T>>> podOpt;
          if (snapshot.hasError) {
            podOpt = Some(
              Err(snapshot.error!, stackTrace: snapshot.stackTrace),
            );
          } else if (pod != null) {
            podOpt = Some(pod);
          } else {
            podOpt = const None();
          }
          return builder(
            context,
            PodBuilderSnapshot(
              pod: podOpt,
              value: Option.from(cached is Result<T> ? cached : null),
              child: child,
            ),
          );
        }
      },
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodResultBuilder<T extends Object> extends StatefulWidget {
  //
  //
  //

  final Result<ValueListenable<T>> pod;
  final TOnOptionBuilder<T, PodBuilderSnapshot<T>> builder;
  final void Function(ValueListenable<T> pod)? onDispose;
  final Duration? debounceDuration;
  final Duration? cacheDuration;
  final Widget? child;

  //
  //
  //

  const PodResultBuilder({
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
  State<PodResultBuilder<T>> createState() => PodResultBuilderState<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodResultBuilderState<T extends Object>
    extends State<PodResultBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild;
  late Result<T> _value;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _setValue(useCache: true);
    _cacheValue();
    UNSAFE:
    widget.pod.ifOk((self, ok) => ok.unwrap().addListener(_valueChanged)).end();
  }

  //
  //
  //

  @override
  void didUpdateWidget(PodResultBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalidate the cache-key memo so the next [_resolvedCacheKey]
    // call recomputes against the new widget.key / widget.pod.
    _cacheKeyComputed = false;
    _cachedCacheKey = null;
    UNSAFE:
    {
      oldWidget.pod
          .ifOk((self, ok) => ok.unwrap().removeListener(_valueChanged))
          .end();
      // When the pod identity changes under the same widget key, the cache
      // still holds the previous pod's value. Reading from the cache here
      // would shadow the new pod's live value until the new pod first fires.
      final podIdentityChanged = !identical(
        oldWidget.pod.isOk() ? oldWidget.pod.unwrap() : null,
        widget.pod.isOk() ? widget.pod.unwrap() : null,
      );
      _setValue(useCache: !podIdentityChanged);
      _cacheValue();
      widget.pod
          .ifOk((self, ok) => ok.unwrap().addListener(_valueChanged))
          .end();
    }
  }

  //
  //
  //

  /// Memoised cache key. `null` means "not yet computed"; once computed
  /// it stays valid until [didUpdateWidget] invalidates it. The compound
  /// key (widget key + pod identityHashCode) is the same for every call
  /// during a single mount, so we save the string allocation on every
  /// pod fire / build. See v0.20.0 O4.
  String? _cachedCacheKey;
  bool _cacheKeyComputed = false;

  /// Returns the cache key for the current widget+pod pair, or `null` if
  /// caching is disabled for this build.
  ///
  /// The pod's [identityHashCode] is appended to the widget key so two
  /// `PodBuilder`s with the same `Key` but different pods cannot read
  /// each other's cached values. This used to be possible: a fresh
  /// mount with the same widget key but a different pod would show the
  /// *previous* pod's value for the first frame (a medical-grade hazard
  /// — one frame of wrong data is one frame too many). See v0.20.0 A1.
  String? _resolvedCacheKey() {
    if (_cacheKeyComputed) return _cachedCacheKey;
    final widgetKey = widget.key;
    if (widgetKey == null) {
      _cacheKeyComputed = true;
      return null;
    }
    if (widget.pod.isErr()) {
      _cacheKeyComputed = true;
      return null;
    }
    UNSAFE:
    final p = widget.pod.unwrap();
    _cachedCacheKey = '$widgetKey|${identityHashCode(p)}';
    _cacheKeyComputed = true;
    return _cachedCacheKey;
  }

  /// Reads `_value` from either the cache (when [useCache] is `true` and a
  /// keyed entry exists for this exact widget+pod pair) or the pod's
  /// current value.
  void _setValue({bool useCache = false}) {
    if (useCache) {
      final key = _resolvedCacheKey();
      if (key != null) {
        final cached = PodBuilderCacheManager.i.get(key);
        final cachedValue = cached is Result<T> ? cached : null;
        if (cachedValue != null) {
          _value = cachedValue;
          return;
        }
      }
    }
    _value = widget.pod.map((e) => e.value);
  }

  //
  //
  //

  void _cacheValue() {
    final key = _resolvedCacheKey();
    if (key == null) return;
    PodBuilderCacheManager.i.cache(
      key,
      _value,
      cacheDuration: widget.cacheDuration,
    );
  }

  //
  //
  //

  Timer? _debounceTimer;

  /// Stable tear-off so [addListener] / [removeListener] always see the
  /// same identity across rebuilds. Reads [widget.debounceDuration] at
  /// call time so a parent that swaps debounce on the fly takes effect on
  /// the next event — earlier this was a `late` closure that captured
  /// the *initial* duration and silently ignored updates.
  late final VoidCallback _valueChanged = _onPodChange;

  void _onPodChange() {
    final dur = widget.debounceDuration;
    if (dur != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(dur, __valueChanged);
    } else {
      _debounceTimer?.cancel();
      __valueChanged();
    }
  }

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
      PodBuilderSnapshot(
        pod: Some(widget.pod),
        value: Some(_value),
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
    UNSAFE:
    if (widget.pod.isOk()) {
      widget.pod.unwrap().removeListener(_valueChanged);
      widget.onDispose?.call(widget.pod.unwrap());
    } else {
      Log.err('Tried to dispose Err<ValueListenable<T>>!', tags: {#df_pod});
    }
    super.dispose();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final class PodBuilderSnapshot<T extends Object> extends OnOptionSnapshot<T> {
  final Option<Result<ValueListenable<T>>> pod;

  const PodBuilderSnapshot({
    required this.pod,
    required super.value,
    required super.child,
  });
}

typedef TOnOptionBuilder<T extends Object,
        TSnapshot extends OnOptionSnapshot<T>>
    = Widget Function(BuildContext context, TSnapshot snapshot);

final class OnOptionSnapshot<T extends Object> extends BuilderSnapshot {
  final Option<Result<T>> value;
  const OnOptionSnapshot({required this.value, required super.child});
}
