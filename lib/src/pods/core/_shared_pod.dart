//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. The use of this
// source code is governed by an MIT-style license described in the LICENSE
// file located in this project's root directory.
//
// See: https://opensource.org/license/mit
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'core.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

/// A Pod that persists its value in shared preferences, allowing for seamless\
/// data storage and retrieval across app sessions.
base class SharedPod<A, B> extends RootPod<A?> {
  //
  //
  //

  static dynamic _sharedPreferences;

  final String key;

  final FutureOr<A?>? Function(B? rawValue) fromValue;
  final FutureOr<B?>? Function(A? value) toValue;
  final A? initialValue;

  //
  //
  //

  SharedPod(
    this.key, {
    required this.fromValue,
    required this.toValue,
    this.initialValue,
  }) : super(initialValue);

  //
  //
  //

  @override
  Future<void> set(A? newValue) async {
    if (_isEquatable(newValue)) {
      final v = await toValue(newValue);
      await shared_preferences.loadLibrary();
      _sharedPreferences ??=
          await shared_preferences.SharedPreferences.getInstance();
      switch (v) {
        case String s:
          await _sharedPreferences!.setString(key, s);
          break;
        case Iterable<String> list:
          await _sharedPreferences!.setStringList(key, list.toList());
          break;
        case bool b:
          await _sharedPreferences!.setBool(key, b);
          break;
        case int i:
          await _sharedPreferences!.setInt(key, i);
          break;
        case double d:
          await _sharedPreferences!.setDouble(key, d);
          break;
        default:
          await _sharedPreferences!.remove(key);
          return;
      }
      if (!isDisposed) {
        _value = newValue;
        notifyListeners();
      }
    }
  }

  //
  //
  //

  bool _isEquatable(A? newValue) {
    if (!isEquatable<A>() || newValue != _value) {
      return true;
    }
    return false;
  }

  //
  //
  //

  @override
  Future<void> refresh() async {
    await shared_preferences.loadLibrary();
    _sharedPreferences ??=
        await shared_preferences.SharedPreferences.getInstance();
    final v = _sharedPreferences!.get(key) as B?;
    if (v != null) {
      final newValue = await fromValue(v);
      super._set(newValue);
    }
  }
}
