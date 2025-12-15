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
          return builder(
            context,
            PodBuilderSnapshot(
              pod: Option.from(pod),
              value: Option.from(
                PodBuilderCacheManager.i.cacheManager.get(key?.toString())
                    as Result<T>?,
              ),
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
    _setValue();
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
    UNSAFE:
    {
      oldWidget.pod
          .ifOk((self, ok) => ok.unwrap().removeListener(_valueChanged))
          .end();
      _setValue();
      _cacheValue();
      widget.pod
          .ifOk((self, ok) => ok.unwrap().addListener(_valueChanged))
          .end();
    }
  }

  //
  //
  //

  void _setValue() {
    final key = widget.key;
    if (key != null) {
      final cachedValue = PodBuilderCacheManager.i.cacheManager
          .get(key.toString()) as Result<T>?;
      if (cachedValue != null) {
        _value = cachedValue;
        return;
      }
    }

    _value = widget.pod.map((e) => e.value);
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
      _value,
      cacheDuration: widget.cacheDuration,
    );
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
      Log.err('Tried to dispose Err<ValueListenable<T>>!', {#df_pod});
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
    = Widget Function(
  BuildContext context,
  TSnapshot snapshot,
);

final class OnOptionSnapshot<T extends Object> extends BuilderSnapshot {
  final Option<Result<T>> value;
  const OnOptionSnapshot({required this.value, required super.child});
}
