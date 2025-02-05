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
      return _PodBuilder(
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
            return _PodBuilder(
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
              PodBuilderSnapshot<T>(
                pod: null,
                value: null,
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

@immutable
final class _PodBuilder<T> extends StatefulWidget {
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

  const _PodBuilder({
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
  State<_PodBuilder<T>> createState() => _PodBuilderState<T>();
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _PodBuilderState<T> extends State<_PodBuilder<T>> {
  //
  //
  //

  late final Widget? _staticChild;
  late T _value;

  //
  //
  //

  @override
  void initState() {
    super.initState();
    _staticChild = widget.child;
    _value = widget.pod.value;
    widget.pod.addListener(_valueChanged!);
  }

  //
  //
  //

  @override
  void didUpdateWidget(_PodBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pod != widget.pod) {
      oldWidget.pod.removeListener(_valueChanged!);
      _value = widget.pod.value;
      widget.pod.addListener(_valueChanged!);
    }
  }

  //
  //
  //

  Timer? _debounceTimer;

  /// Allows initial data to be set immediately for responsiveness even if
  /// the debounce duration is long.
  bool _skipInitialDebounce = true;

  // ignore: prefer_final_fields
  late void Function()? _valueChanged = widget.debounceDuration != null
      ? () {
          if (_skipInitialDebounce) {
            _skipInitialDebounce = false;
            __valueChanged();
            return;
          } else {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(widget.debounceDuration!, () {
              __valueChanged();
            });
          }
        }
      : __valueChanged;

  @pragma('vm:prefer-inline')
  void __valueChanged() {
    if (mounted) {
      setState(() => _value = widget.pod.value);
    }
  }

  //
  //
  //

  @override
  Widget build(BuildContext context) {
    final snapshot = PodBuilderSnapshot(
      pod: widget.pod,
      value: _value,
      child: _staticChild,
    );
    final result = widget.builder(context, snapshot);
    return result;
  }

  //
  //
  //

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.pod.removeListener(_valueChanged!);
    _valueChanged = null;
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
