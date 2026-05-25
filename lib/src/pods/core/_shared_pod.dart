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

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base class SharedPod<A extends Object, B extends Object> extends RootPod<A> {
  //
  //
  //

  SharedPreferences? _sharedPreferences;

  /// Serializes all writes (set/delete/refresh) for this key. Without this,
  /// concurrent calls can interleave their `setString`/`remove` and `_set`
  /// steps and leave the in-memory pod value out of sync with storage when
  /// the underlying preferences backend resolves writes out of order.
  Future<void> _writeQueue = Future<void>.value();

  //
  //
  //

  final String key;
  final A Function(B? rawValue) fromValue;
  final B Function(A value) toValue;
  final A initialValue;

  //
  //
  //

  @protected
  SharedPod(
    this.key, {
    required this.fromValue,
    required this.toValue,
    required this.initialValue,
  }) : super(initialValue);

  //
  //
  //

  /// Creates and initializes a [SharedPod] by loading its value from storage.
  static Future<SharedPod<A, B>> create<A extends Object, B extends Object>(
    String key, {
    required A Function(B? rawValue) fromValue,
    required B Function(A value) toValue,
    required A initialValue,
  }) async {
    final instance = SharedPod<A, B>(
      key,
      fromValue: fromValue,
      toValue: toValue,
      initialValue: initialValue,
    );
    await instance.refresh();
    return instance;
  }

  //
  //
  //

  @override
  Future<void> set(A newValue, {bool notifyImmediately = true}) {
    return _enqueue(() async {
      final v = toValue(newValue);
      _sharedPreferences ??= await _getPrefs();
      switch (v) {
        case final String s:
          await _sharedPreferences!.setString(key, s);
        case final bool b:
          await _sharedPreferences!.setBool(key, b);
        case final int i:
          await _sharedPreferences!.setInt(key, i);
        case final double d:
          await _sharedPreferences!.setDouble(key, d);
        case final Iterable<String> list:
          await _sharedPreferences!.setStringList(key, list.toList());
        default:
          throw Err(
            'SharedPod only supports storing String, int, bool, double, and Iterable<String>. '
            'The provided value type is ${v.runtimeType}.',
          );
      }
      _set(newValue, notifyImmediately: notifyImmediately);
    });
  }

  //
  //
  //

  Future<void> delete({bool notifyImmediately = true}) {
    return _enqueue(() async {
      _sharedPreferences ??= await _getPrefs();
      await _sharedPreferences!.remove(key);
      _set(initialValue, notifyImmediately: notifyImmediately);
    });
  }

  //
  //
  //

  @override
  Future<void> refresh({bool notifyImmediately = true}) {
    return _enqueue(() async {
      _sharedPreferences ??= await _getPrefs();
      final v = _sharedPreferences!.get(key);
      final newValue = fromValue(v is B ? v : null);
      _set(newValue, notifyImmediately: notifyImmediately);
    });
  }

  /// Wraps [SharedPreferences.getInstance] with an actionable error so
  /// the most common worker-isolate misconfiguration fails loudly with a
  /// fix-it hint rather than a bare `MissingPluginException` from the
  /// platform-channel layer.
  ///
  /// The two failure modes this surfaces:
  /// 1. The caller is on a background isolate and never wired up
  ///    `BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken)`
  ///    at the worker's entry point.
  /// 2. The `shared_preferences` plugin is missing from the build (rare;
  ///    usually a `flutter pub get` problem).
  Future<SharedPreferences> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e, s) {
      throw StateError(
        'SharedPod failed to initialise SharedPreferences for key "$key".\n'
        '\n'
        'If you are using SharedPod from a worker (background) isolate, '
        'the worker entry point must call '
        '`BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken)` '
        'BEFORE any SharedPod operation. The token must be obtained on '
        'the root isolate (`RootIsolateToken.instance!`) and passed to '
        '`Isolate.spawn`.\n'
        '\n'
        'If you are on the root isolate, check that the '
        '`shared_preferences` plugin is registered (run `flutter pub get` '
        'and rebuild).\n'
        '\n'
        'Underlying error: $e\n'
        'Stack: $s',
      );
    }
  }

  /// Chains [task] onto [_writeQueue] so concurrent writes commit in call
  /// order. The returned future completes for this specific task; an error
  /// in one task does not abort subsequent ones (the queue absorbs it).
  /// Tasks that resolve after [dispose] become no-ops — without this guard
  /// the trailing [_set] would hit the disposed-pod assertion in
  /// [WeakChangeNotifier.notifyListeners].
  ///
  /// Errors are also logged via `df_log` so a fire-and-forget caller
  /// (`pod.set(x); // no await`) does not lose visibility on a failed
  /// disk write. The returned [Future] still surfaces the error to
  /// `await`ing callers — logging is additive, not a substitute.
  Future<void> _enqueue(Future<void> Function() task) {
    final result = _writeQueue.then((_) async {
      if (isDisposed) return;
      await task();
    });
    _writeQueue = result.catchError((Object e, StackTrace s) {
      Log.err(e, tags: {#df_pod});
    });
    return result;
  }
}
