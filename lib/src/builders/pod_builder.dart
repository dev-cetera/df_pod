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

final class PodBuilder<T> extends StatelessWidget {
  //
  //
  //

  final TFutureListenable<T> pod;
  final TOnValueBuilder<T?, PodBuilderSnapshot<T>> builder;
  final void Function(ValueListenable<T> pod)? onDispose;
  final Duration? debounceDuration;

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
    this.child,
  });

  //
  //
  //

  // Constructs a [PodBuilder] with a zero debounce duration.
  @visibleForTesting
  const PodBuilder.immediate({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.child,
  }) : debounceDuration = Duration.zero;

  /// Constructs a [PodBuilder] with a short debounce duration of 100ms.
  const PodBuilder.short({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.child,
  }) : debounceDuration = const Duration(milliseconds: 100);

  /// Constructs a [PodBuilder] with a long debounce duration of 500ms.
  const PodBuilder.long({
    super.key,
    required this.pod,
    required this.builder,
    this.onDispose,
    this.child,
  }) : debounceDuration = const Duration(milliseconds: 500);

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
              debounceDuration: debounceDuration,
              child: child,
            );
          } else {
            return builder(
              context,
              PodBuilderSnapshot<T>(pod: null, value: null, child: child),
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

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _setValue();
    _refresh();
    widget.pod.addListener(_valueChanged);
  }

  @override
  void didUpdateWidget(SyncPodBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pod != widget.pod) {
      oldWidget.pod.removeListener(_valueChanged);
      _setValue();
      ;
      widget.pod.addListener(_valueChanged);
    }
  }

  void _setValue() {
    _value = widget.pod.value;
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
