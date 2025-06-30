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

import 'package:df_safer_dart/_common.dart';

import '/_common.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A class that can be extended or mixed in that provides a change notification
/// API using [VoidCallback] for notifications. It is a modified version of
/// Flutter's [ChangeNotifier] that uses [WeakReference] for its listeners.
///
/// This prevents the notifier from holding a strong reference to its listeners,
/// a common source of memory leaks if `removeListener` is not called. Listeners
/// are automatically marked for removal when they are garbage collected.
///
/// It is O(1) for adding listeners and O(N) for removing listeners and dispatching
/// notifications (where N is the number of listeners).
mixin class WeakChangeNotifier implements Listenable {
  int _count = 0;
  List<WeakReference<VoidCallback>?> _listeners = _emptyListeners;
  static final _emptyListeners = List<WeakReference<VoidCallback>?>.filled(
    0,
    null,
  );

  int _notificationCallStackDepth = 0;
  int _reentrantlyRemovedListeners = 0;
  bool _isDisposed = false;

  // --- Debugging ---
  static bool printGarbageCollectionStatus = false;
  List<Finalizer<VoidCallback>>? _debugFinalizers;
  bool _debugFinalizersAttached = false;

  /// Whether any listeners are currently registered.
  ///
  /// Clients should not depend on this value for their behavior, because having
  /// one listener's logic change when another listener happens to start or stop
  /// listening will lead to extremely hard-to-track bugs.
  ///
  /// This method returns false if [dispose] has been called.
  @protected
  bool get hasListeners => _count > 0;

  /// Registers a listener that will be called only once when the object
  /// notifies its listeners. After the listener is called, it is automatically
  /// removed.
  void addSingleExecutionListener(VoidCallback listener) {
    // This is a special case that requires a strong reference to the temporary
    // wrapper closure. We hold it until it's called.
    late final VoidCallback tempListener;
    tempListener = () {
      try {
        listener();
      } finally {
        removeListener(tempListener);
      }
    };
    addStrongRefListener(strongRefListener: tempListener);
  }

  /// Register a closure to be called when the object notifies its listeners.
  ///
  /// The [strongRefListener] MUST be held by a strong reference by the object
  /// that adds it. If the listener is an anonymous function or a reference to a
  /// function that goes out of scope, it will be garbage collected and
  /// automatically removed without notice.
  ///
  /// This method must not be called after [dispose] has been called.
  ///
  /// ### Example of Correct Usage:
  ///
  /// ```dart
  /// class MyWidgetState extends State<MyWidget> {
  ///   // Assign the listener to a field to maintain a strong reference.
  ///   late final VoidCallback _myListener = () => print('Notified!');
  ///
  ///   @override
  ///   void initState() {
  ///     super.initState();
  ///     myNotifier.addStrongRefListener(strongRefListener: _myListener);
  ///   }
  ///
  ///   @override
  ///   void dispose() {
  ///     myNotifier.removeListener(_myListener);
  ///     super.dispose();
  ///   }
  /// }
  /// ```
  void addStrongRefListener({
    @mustBeStrongRefOrError required VoidCallback strongRefListener,
  }) {
    assert(!_isDisposed, 'A $runtimeType was used after being disposed.');

    // Per the Listenable contract, addListener should be callable with the same
    // listener multiple times. We do not de-duplicate.

    if (_count == _listeners.length) {
      _growListenersList();
    }
    _listeners[_count++] = WeakReference(strongRefListener);
    _attachFinalizer(strongRefListener);
  }

  /// Implements the [Listenable] interface.
  ///
  /// Use [addStrongRefListener] instead, as this method's name can be misleading
  /// about the weak reference behavior.
  @protected
  @override
  void addListener(@mustBeStrongRefOrError VoidCallback listener) {
    addStrongRefListener(strongRefListener: listener);
  }

  /// Remove a previously registered closure from the list of closures that are
  /// notified when the object changes.
  ///
  /// If the given listener is not registered, the call is ignored. This method
  /// is allowed to be called on disposed instances for usability reasons.
  @override
  void removeListener(VoidCallback listener) {
    if (_isDisposed) return;

    for (var i = 0; i < _count; i++) {
      final listenerRef = _listeners[i];
      if (listenerRef?.target == listener) {
        if (_notificationCallStackDepth > 0) {
          // If we are in the middle of a notification, we don't resize the list.
          // We just set the listener to null. It will be cleaned up later.
          _listeners[i] = null;
          _reentrantlyRemovedListeners++;
        } else {
          // When we are outside the notifyListeners iterations, we can
          // effectively shrink the list.
          _removeAt(i);
        }
        break;
      }
    }
  }

  /// Discards any resources used by the object. After this is called, the
  /// object is not in a usable state and should be discarded.
  ///
  /// This method should only be called by the object's owner.
  @mustCallSuper
  void dispose() {
    assert(!_isDisposed, 'This $runtimeType has already been disposed.');
    assert(
      _notificationCallStackDepth == 0,
      'The "dispose()" method on $this was called during a call to "notifyListeners()".',
    );
    _isDisposed = true;
    _listeners = _emptyListeners;
    _count = 0;
    _detachAllFinalizers();
  }

  /// Call all the registered listeners.
  ///
  /// Call this method whenever the object changes. Listeners that are added
  /// during this iteration will not be visited. Listeners that are removed
  /// during this iteration will not be visited after they are removed.
  @protected
  @visibleForTesting
  @pragma('vm:notify-debugger-on-exception')
  void notifyListeners() {
    assert(!_isDisposed, 'A $runtimeType was used after being disposed.');
    if (_count == 0) {
      return;
    }

    // To allow potential listeners to recursively call notifyListener, we track
    // the number of times this method is called in `_notificationCallStackDepth`.
    _notificationCallStackDepth++;

    final end = _count;
    for (var i = 0; i < end; i++) {
      final listenerRef = _listeners[i];
      try {
        // Also check if the listener was garbage collected mid-loop.
        listenerRef?.target?.call();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'df_pod',
            context: ErrorDescription(
              'while dispatching notifications for $runtimeType',
            ),
          ),
        );
      }
    }

    _notificationCallStackDepth--;

    if (_notificationCallStackDepth == 0) {
      // We really remove the listeners when all notifications are done.
      _compactListeners();
    }
  }

  /// Grows the internal listeners list when it's full.
  void _growListenersList() {
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

  /// Removes a listener at a specific index and compacts the list.
  void _removeAt(int index) {
    _count--;
    // Shrink the list if it's sparsely populated to conserve memory.
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
      // Otherwise, just shift elements in the existing list.
      for (var i = index; i < _count; i++) {
        _listeners[i] = _listeners[i + 1];
      }
      _listeners[_count] = null;
    }
  }

  /// Compacts the list by removing all null or dead references.
  /// This is called after notifications are complete.
  void _compactListeners() {
    // First, scan for any garbage-collected listeners and mark them for removal.
    for (var i = 0; i < _count; i++) {
      if (_listeners[i]?.target == null) {
        _listeners[i] = null;
        _reentrantlyRemovedListeners++;
      }
    }

    if (_reentrantlyRemovedListeners > 0) {
      final newLength = _count - _reentrantlyRemovedListeners;
      if (newLength * 2 <= _listeners.length) {
        // As in _removeAt, we only shrink the list when the real number of
        // listeners is half the length of our list.
        final newListeners = List<WeakReference<VoidCallback>?>.filled(
          newLength,
          null,
        );
        var newIndex = 0;
        for (var i = 0; i < _count; i++) {
          final listenerRef = _listeners[i];
          if (listenerRef != null) {
            newListeners[newIndex++] = listenerRef;
          }
        }
        _listeners = newListeners;
      } else {
        // Otherwise we put all the null references at the end by compacting in-place.
        var writeIndex = 0;
        for (var readIndex = 0; readIndex < _count; readIndex++) {
          final listenerRef = _listeners[readIndex];
          if (listenerRef != null) {
            if (writeIndex != readIndex) {
              _listeners[writeIndex] = listenerRef;
            }
            writeIndex++;
          }
        }
        for (var i = newLength; i < _count; i++) {
          _listeners[i] = null;
        }
      }

      _reentrantlyRemovedListeners = 0;
      _count = newLength;
    }
  }

  void _attachFinalizer(VoidCallback listener) {
    if (printGarbageCollectionStatus && kDebugMode) {
      _debugFinalizers ??= [];
      final finalizer = Finalizer<VoidCallback>((_) {
        if (kDebugMode && !_isDisposed) {
          Log.alert(
            'A listener has been garbage collected. This is often desired, but ensure it was not due to a programming error where the listener was not held with a strong reference.',
            {#df_pod},
          );
        }
      });
      finalizer.attach(listener, listener, detach: this);
      _debugFinalizers!.add(finalizer);
      _debugFinalizersAttached = true;
    }
  }

  void _detachAllFinalizers() {
    if (_debugFinalizersAttached) {
      _debugFinalizers?.forEach((f) => f.detach(this));
      _debugFinalizers = null;
      _debugFinalizersAttached = false;
    }
  }
}

// OLDER VERSION:

// //.title
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //
// // Dart/Flutter (DF) Packages by dev-cetera.com & contributors. The use of this
// // source code is governed by an MIT-style license described in the LICENSE
// // file located in this project's root directory.
// //
// // See: https://opensource.org/license/mit
// //
// // ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
// //.title~

// import 'package:flutter/foundation.dart';

// // ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

// /// A modified version of [ChangeNotifier] that uses [WeakReference] for its
// /// listeners.
// mixin class WeakChangeNotifier implements Listenable {
//   //
//   //
//   //

//   int _count = 0;
//   List<WeakReference<VoidCallback>?> _listeners = _emptyListeners;
//   static final _emptyListeners = List<WeakReference<VoidCallback>?>.filled(
//     0,
//     null,
//   );
//   int _notificationCallStackDepth = 0;
//   int _reentrantlyRemovedListeners = 0;

//   //
//   //
//   //

//   static bool printGarbageCollectionStatus = false;
//   List<Finalizer<VoidCallback>>? _debugFinalizers;

//   //
//   //
//   //

//   bool get hasListeners => _count > 0;

//   //
//   //
//   //

//   /// Registers a listener that will be called only once when the object
//   /// notifies its listeners. After the listener is called, it is automatically
//   /// removed.
//   void addSingleExecutionListener(VoidCallback listener) {
//     late final VoidCallback tempListener;
//     tempListener = () {
//       listener();
//       removeListener(tempListener);
//     };
//     // ignore: deprecated_member_use_from_same_package
//     addListener(tempListener);
//   }

//   /// Register a closure to be called when the object notifies its listeners.
//   ///
//   /// The listener must be strongly referenced, meaning it should be stored in
//   /// an instance variable or field. If not, it will be garbage collected
//   /// prematurely.
//   ///
//   /// **For example:**
//   ///
//   /// ```dart
//   ///
//   /// // 👍 CORRECT - Instance functions are strongly referenced:
//   ///
//   /// final listener = () {
//   ///   print('Pod value changed');
//   /// };
//   /// weakChangeNotifier.addStrongRefListener(strongRefListener: listener);
//   ///
//   /// // ❌ INCORRECT - Functions defined like this are not strongly referenced:
//   ///
//   /// void listener() {
//   ///   print('Pod value changed');
//   /// }
//   ///
//   /// weakChangeNotifier.addStrongRefListener(strongRefListener: listener);
//   ///
//   /// // ❌ INCORRECT - Anonymous functions are not strongly referenced:
//   ///
//   /// weakChangeNotifier.addStrongRefListener(strongRefListener: () {
//   ///  print('Pod value changed');
//   /// });
//   @visibleForTesting
//   void addStrongRefListener({required VoidCallback strongRefListener}) {
//     // ignore: deprecated_member_use_from_same_package
//     addListener(strongRefListener);
//   }

//   /// ❌ Do not use this method directly. Use [addStrongRefListener] instead.
//   @Deprecated(
//     'Do not use this method directly. Use [addStrongRefListener] instead',
//   )
//   @protected
//   @override
//   void addListener(VoidCallback listener) {
//     _garbageCollect();
//     _maybeReallocate();
//     _listeners[_count++] = WeakReference(listener);
//     if (printGarbageCollectionStatus && kDebugMode) {
//       _debugFinalizers ??= [];
//       (_debugFinalizers ??= [])
//         ..add(
//           Finalizer<VoidCallback>((target) {
//             if (kDebugMode) {
//               print(
//                 '[$WeakChangeNotifier] A listener of type "$runtimeType" has been garbage collected.',
//               );
//             }
//           }),
//         )
//         ..last.attach(listener, () {});
//     }
//   }

//   void _maybeReallocate() {
//     if (_listeners.length == _count) {
//       if (_count == 0) {
//         _listeners = List<WeakReference<VoidCallback>?>.filled(1, null);
//       } else {
//         final newListeners = List<WeakReference<VoidCallback>?>.filled(
//           _listeners.length * 2,
//           null,
//         );
//         for (var i = 0; i < _count; i++) {
//           newListeners[i] = _listeners[i];
//         }
//         _listeners = newListeners;
//       }
//     }
//   }

//   //
//   //
//   //

//   @override
//   void removeListener(VoidCallback listener) {
//     for (var i = 0; i < _count; i++) {
//       final listenerAtIndex = _listeners[i];
//       final target = listenerAtIndex?.target;
//       // Remove the matching listener as well as weak references that no longer
//       // point to listeners, same as _garbageCollect().
//       if (target == listener || (target == null && listenerAtIndex != null)) {
//         if (_notificationCallStackDepth > 0) {
//           _listeners[i] = null;
//           _reentrantlyRemovedListeners++;
//         } else {
//           _removeAt(i);
//         }
//         break;
//       }
//     }
//   }

//   void _garbageCollect() {
//     for (var i = 0; i < _count; i++) {
//       final listenerAtIndex = _listeners[i];
//       final target = listenerAtIndex?.target;
//       if (target == null && listenerAtIndex != null) {
//         if (_notificationCallStackDepth > 0) {
//           _listeners[i] = null;
//           _reentrantlyRemovedListeners++;
//         } else {
//           _removeAt(i);
//         }
//         break;
//       }
//     }
//   }

//   void _removeAt(int index) {
//     _count -= 1;
//     if (_count * 2 <= _listeners.length) {
//       final newListeners = List<WeakReference<VoidCallback>?>.filled(
//         _count,
//         null,
//       );
//       for (var i = 0; i < index; i++) {
//         newListeners[i] = _listeners[i];
//       }
//       for (var i = index; i < _count; i++) {
//         newListeners[i] = _listeners[i + 1];
//       }
//       _listeners = newListeners;
//     } else {
//       for (var i = index; i < _count; i++) {
//         _listeners[i] = _listeners[i + 1];
//       }
//       _listeners[_count] = null;
//     }
//   }

//   //
//   //
//   //

//   @mustCallSuper
//   void dispose() {
//     _listeners = _emptyListeners;
//     _count = 0;
//   }

//   //
//   //
//   //

//   @pragma('vm:notify-debugger-on-exception')
//   void notifyListeners() {
//     _garbageCollect();

//     if (_count == 0) {
//       return;
//     }

//     // Call all listeners anc calculate the call stack depth, in case of
//     // recursive calling.
//     _notificationCallStackDepth++;
//     final end = _count;
//     for (var i = 0; i < end; i++) {
//       try {
//         _listeners[i]?.target?.call();
//       } catch (exception, stack) {
//         FlutterError.reportError(
//           FlutterErrorDetails(
//             exception: exception,
//             stack: stack,
//             library: 'df_pod',
//             context: ErrorDescription(
//               'while dispatching notifications for $runtimeType',
//             ),
//             informationCollector: () => <DiagnosticsNode>[
//               DiagnosticsProperty<WeakChangeNotifier>(
//                 'The $runtimeType sending notification was',
//                 this,
//                 style: DiagnosticsTreeStyle.errorProperty,
//               ),
//             ],
//           ),
//         );
//       }
//     }
//     _notificationCallStackDepth--;

//     // Remove listeners scheduled for removal by [removeListener].
//     if (_notificationCallStackDepth == 0 && _reentrantlyRemovedListeners > 0) {
//       final newLength = _count - _reentrantlyRemovedListeners;
//       if (newLength * 2 <= _listeners.length) {
//         final newListeners = List<WeakReference<VoidCallback>?>.filled(
//           newLength,
//           null,
//         );
//         var newIndex = 0;
//         for (var i = 0; i < _count; i++) {
//           final listener = _listeners[i];
//           if (listener != null) {
//             newListeners[newIndex++] = listener;
//           }
//         }
//         _listeners = newListeners;
//       } else {
//         for (var i = 0; i < newLength; i += 1) {
//           if (_listeners[i] == null) {
//             var swapIndex = i + 1;
//             while (_listeners[swapIndex] == null) {
//               swapIndex += 1;
//             }
//             _listeners[i] = _listeners[swapIndex];
//             _listeners[swapIndex] = null;
//           }
//         }
//       }
//       _reentrantlyRemovedListeners = 0;
//       _count = newLength;
//     }
//   }
// }
