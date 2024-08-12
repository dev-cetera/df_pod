//.title
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// Dart/Flutter (DF) Packages by DevCetra.com & contributors. See LICENSE file
// in root directory.
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//.title~

part of 'pod.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ChildPod<A, B> extends Pod<B> {
  //
  //
  //

  final List<Pod<A>> parents;
  final B Function(List<A> parentValues) reducer;
  final List<A> Function(List<A> parentValues, B childValue)? updateParents;

  //
  //
  //

  ChildPod({
    required this.parents,
    required this.reducer,
    required this.updateParents,
    bool temp = false,
  }) : super(
          reducer(parents.map((p) => p.value).toList()),
          temp: temp,
        ) {
    for (var parent in parents) {
      parent._addChild(this);
      parent.addListener(refresh);
    }
  }

  //
  //
  //

  factory ChildPod.temp({
    required List<Pod<A>> parents,
    required B Function(List<A> parentValues) reducer,
    List<A> Function(List<A> parentValues, B childValue)? updateParents,
  }) {
    return ChildPod(
      parents: parents,
      reducer: reducer,
      updateParents: updateParents,
      temp: true,
    );
  }

  //
  //
  //

  @override
  Future<void> refresh() async {
    final newValue = reducer(parents.map((p) => p.value).toList());
    await set(newValue);
  }

  //
  //
  //

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (this.updateParents != null) {
      final oldParentValues = parents.map((e) => e.value).toList();
      final newParentValues = updateParents!(oldParentValues, value);
      for (var n = 0; n < parents.length; n++) {
        parents.elementAt(n).set(newParentValues.elementAt(n));
      }
    }
  }

  //
  //
  //

  @override
  void dispose() {
    for (var parent in parents) {
      parent._removeChild(this);
      parent.removeListener(refresh);
    }
    super.dispose();
  }
}
