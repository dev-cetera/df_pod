//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. See LICENSE file
// in root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

import 'package:shared_preferences/shared_preferences.dart';

import 'package:df_pod/df_pod.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class SharedPod<A, B> extends Pod<A?> {
  //
  //
  //

  static SharedPreferences? _sharedPreferences;

  final String key;

  final A? Function(B? rawValue)? fromValue;
  final B? Function(A? value)? toValue;

  //
  //
  //

  SharedPod.empty(
    this.key, {
    super.disposable = true,
    super.temp = false,
    this.fromValue,
    this.toValue,
  }) : super(null);

  //
  //
  //

  @override
  Future<void> set(A? newValue) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    final v = toValue?.call(newValue);
    if (v != null) {
      if (v is String) {
        await _sharedPreferences!.setString(key, v);
      }
      if (v is Iterable<String>) {
        await _sharedPreferences!.setStringList(key, v.toList());
      }
      if (v is bool) {
        await _sharedPreferences!.setBool(key, v);
      }
      if (v is int) {
        await _sharedPreferences!.setInt(key, v);
      }
      if (v is double) {
        await _sharedPreferences!.setDouble(key, v);
      }
      return;
    }
    await _sharedPreferences!.remove(key);
    await super.set(newValue);
  }

  //
  //
  //

  Future<void> refresh() async {
    if (fromValue != null) {
      _sharedPreferences ??= await SharedPreferences.getInstance();
      final v = _sharedPreferences!.get(key) as B?;
      if (v != null) {
        final newValue = fromValue!(v);
        await super.set(newValue);
      }
    }
  }
}
