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
  Future<void> set(A newValue, {bool notifyImmediately = true}) async {
    final v = toValue(newValue);
    _sharedPreferences ??= await SharedPreferences.getInstance();
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
  }

  //
  //
  //

  Future<void> delete({bool notifyImmediately = true}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    await _sharedPreferences!.remove(key);
    _set(initialValue, notifyImmediately: notifyImmediately);
  }

  //
  //
  //

  @override
  Future<void> refresh({bool notifyImmediately = true}) async {
    _sharedPreferences ??= await SharedPreferences.getInstance();
    final v = _sharedPreferences!.get(key);
    final newValue = fromValue(v as B?);
    _set(newValue, notifyImmediately: notifyImmediately);
  }
}
