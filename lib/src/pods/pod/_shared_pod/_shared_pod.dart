//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. Use of this
// source code is governed by an MIT-style license that can be found in the
// LICENSE file.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of '../parts.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

base class SharedPod<A, B> extends Pod<A?> {
  //
  //
  //

  static SharedPreferences? _sharedPreferences;

  final String key;

  final A? Function(B? rawValue) fromValue;
  final B? Function(A? value) toValue;

  //
  //
  //

  SharedPod(
    this.key, {
    required this.fromValue,
    required this.toValue,
    super.onBeforeDispose,
  }) : super(null);

  SharedPod._temp(
    this.key, {
    required this.fromValue,
    required this.toValue,
    super.onBeforeDispose,
  }) : super._temp(null);

  SharedPod._global(
    this.key, {
    required this.fromValue,
    required this.toValue,
  }) : super._global(null);

  //
  //
  //

  @override
  Future<void> set(A? newValue) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    final v = toValue(newValue);
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
    await super.set(newValue);
  }

  //
  //
  //

  @override
  Future<void> refresh() async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    final v = _sharedPreferences!.get(key) as B?;
    if (v != null) {
      final newValue = fromValue(v);
      await super.set(newValue);
    }
  }
}
