//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// An enhanced alternative to [ValueNotifier] that provides additional
/// lifecycle management capabilities through the [PodListenableDisposeMixin].
abstract class PodNotifier<T> extends ChangeNotifier with PodListenableDisposeMixin<T> {
  //
  //
  //

  T _value;

  @override
  T get value => _value;

  final TOnBeforeDispose<T>? onBeforeDispose;

  /// Creates a new [Pod] from the given [value]. Calls [onBeforeDispose]
  /// immediately before disposing.
  PodNotifier(
    this._value, {
    this.onBeforeDispose,
  });

  /// Adds a [listener] to this [PodNotifier] that will be triggered only once.
  /// Once the [listener] is called, it is automatically removed, unlike the
  /// persistent behavior of [addListener].
  ///
  /// This method is useful when you need a callback to execute a single time
  /// in response to a change, ensuring it does not linger in memory or respond
  /// to future changes.
  void addSingleExecutionListener(VoidCallback listener) {
    late final VoidCallback tempListener;
    tempListener = () {
      listener();
      removeListener(tempListener);
    };
    addListener(tempListener);
  }

  /// Calls [onBeforeDispose] then dipsoses this [PodNotifier] if and sets
  /// [isDisposed] to `true`. Successive calls to this method will be ignored.
  @override
  void dispose() {
    super.maybeDispose(() {
      onBeforeDispose?.call(this.value);
      super.dispose();
    });
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

typedef TOnBeforeDispose<T> = void Function(T value)?;