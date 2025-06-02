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

import 'package:flutter/foundation.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A modified version of [ChangeNotifier] that uses [WeakReference] for its
/// listeners.
mixin class WeakChangeNotifier implements Listenable {
  //
  //
  //

  int _count = 0;
  List<WeakReference<VoidCallback>?> _listeners = _emptyListeners;
  static final _emptyListeners = List<WeakReference<VoidCallback>?>.filled(
    0,
    null,
  );
  int _notificationCallStackDepth = 0;
  int _reentrantlyRemovedListeners = 0;

  //
  //
  //

  static bool printGarbageCollectionStatus = false;
  List<Finalizer<VoidCallback>>? _debugFinalizers;

  //
  //
  //

  bool get hasListeners => _count > 0;

  //
  //
  //

  /// Registers a listener that will be called only once when the object
  /// notifies its listeners. After the listener is called, it is automatically
  /// removed.
  void addSingleExecutionListener(VoidCallback listener) {
    late final VoidCallback tempListener;
    tempListener = () {
      listener();
      removeListener(tempListener);
    };
    // ignore: deprecated_member_use_from_same_package
    addListener(tempListener);
  }

  /// Register a closure to be called when the object notifies its listeners.
  ///
  /// The listener must be strongly referenced, meaning it should be stored in
  /// an instance variable or field. If not, it will be garbage collected
  /// prematurely.
  ///
  /// **For example:**
  ///
  /// ```dart
  ///
  /// // 👍 CORRECT - Instance functions are strongly referenced:
  ///
  /// final listener = () {
  ///   print('Pod value changed');
  /// };
  /// weakChangeNotifier.addStrongRefListener(strongRefListener: listener);
  ///
  /// // ❌ INCORRECT - Functions defined like this are not strongly referenced:
  ///
  /// void listener() {
  ///   print('Pod value changed');
  /// }
  ///
  /// weakChangeNotifier.addStrongRefListener(strongRefListener: listener);
  ///
  /// // ❌ INCORRECT - Anonymous functions are not strongly referenced:
  ///
  /// weakChangeNotifier.addStrongRefListener(strongRefListener: () {
  ///  print('Pod value changed');
  /// });
  void addStrongRefListener({required VoidCallback strongRefListener}) {
    // ignore: deprecated_member_use_from_same_package
    addListener(strongRefListener);
  }

  /// ❌ Do not use this method directly. Use [addStrongRefListener] instead.
  @Deprecated(
    'Do not use this method directly. Use [addStrongRefListener] instead',
  )
  @protected
  @override
  void addListener(VoidCallback listener) {
    _garbageCollect();
    _maybeReallocate();
    _listeners[_count++] = WeakReference(listener);
    if (printGarbageCollectionStatus && kDebugMode) {
      _debugFinalizers ??= [];
      (_debugFinalizers ??= [])
        ..add(
          Finalizer<VoidCallback>((target) {
            if (kDebugMode) {
              print(
                '[$WeakChangeNotifier] A listener of type "$runtimeType" has been garbage collected.',
              );
            }
          }),
        )
        ..last.attach(listener, () {});
    }
  }

  void _maybeReallocate() {
    if (_listeners.length == _count) {
      if (_count == 0) {
        _listeners = List<WeakReference<VoidCallback>?>.filled(1, null);
      } else {
        final newListeners = List<WeakReference<VoidCallback>?>.filled(
          _listeners.length * 2,
          null,
        );
        for (var i = 0; i < _count; i++) {
          newListeners[i] = _listeners[i];
        }
        _listeners = newListeners;
      }
    }
  }

  //
  //
  //

  @override
  void removeListener(VoidCallback listener) {
    for (var i = 0; i < _count; i++) {
      final listenerAtIndex = _listeners[i];
      final target = listenerAtIndex?.target;
      // Remove the matching listener as well as weak references that no longer
      // point to listeners, same as _garbageCollect().
      if (target == listener || (target == null && listenerAtIndex != null)) {
        if (_notificationCallStackDepth > 0) {
          _listeners[i] = null;
          _reentrantlyRemovedListeners++;
        } else {
          _removeAt(i);
        }
        break;
      }
    }
  }

  void _garbageCollect() {
    for (var i = 0; i < _count; i++) {
      final listenerAtIndex = _listeners[i];
      final target = listenerAtIndex?.target;
      if (target == null && listenerAtIndex != null) {
        if (_notificationCallStackDepth > 0) {
          _listeners[i] = null;
          _reentrantlyRemovedListeners++;
        } else {
          _removeAt(i);
        }
        break;
      }
    }
  }

  void _removeAt(int index) {
    _count -= 1;
    if (_count * 2 <= _listeners.length) {
      final newListeners = List<WeakReference<VoidCallback>?>.filled(
        _count,
        null,
      );
      for (var i = 0; i < index; i++) {
        newListeners[i] = _listeners[i];
      }
      for (var i = index; i < _count; i++) {
        newListeners[i] = _listeners[i + 1];
      }
      _listeners = newListeners;
    } else {
      for (var i = index; i < _count; i++) {
        _listeners[i] = _listeners[i + 1];
      }
      _listeners[_count] = null;
    }
  }

  //
  //
  //

  @mustCallSuper
  void dispose() {
    _listeners = _emptyListeners;
    _count = 0;
  }

  //
  //
  //

  @pragma('vm:notify-debugger-on-exception')
  void notifyListeners() {
    _garbageCollect();

    if (_count == 0) {
      return;
    }

    // Call all listeners anc calculate the call stack depth, in case of
    // recursive calling.
    _notificationCallStackDepth++;
    final end = _count;
    for (var i = 0; i < end; i++) {
      try {
        _listeners[i]?.target?.call();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'DF Pod',
            context: ErrorDescription(
              'while dispatching notifications for $runtimeType',
            ),
            informationCollector: () => <DiagnosticsNode>[
              DiagnosticsProperty<WeakChangeNotifier>(
                'The $runtimeType sending notification was',
                this,
                style: DiagnosticsTreeStyle.errorProperty,
              ),
            ],
          ),
        );
      }
    }
    _notificationCallStackDepth--;

    // Remove listeners scheduled for removal by [removeListener].
    if (_notificationCallStackDepth == 0 && _reentrantlyRemovedListeners > 0) {
      final newLength = _count - _reentrantlyRemovedListeners;
      if (newLength * 2 <= _listeners.length) {
        final newListeners = List<WeakReference<VoidCallback>?>.filled(
          newLength,
          null,
        );
        var newIndex = 0;
        for (var i = 0; i < _count; i++) {
          final listener = _listeners[i];
          if (listener != null) {
            newListeners[newIndex++] = listener;
          }
        }
        _listeners = newListeners;
      } else {
        for (var i = 0; i < newLength; i += 1) {
          if (_listeners[i] == null) {
            var swapIndex = i + 1;
            while (_listeners[swapIndex] == null) {
              swapIndex += 1;
            }
            _listeners[i] = _listeners[swapIndex];
            _listeners[swapIndex] = null;
          }
        }
      }
      _reentrantlyRemovedListeners = 0;
      _count = newLength;
    }
  }
}
