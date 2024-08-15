# DF Pod

<a href="https://www.buymeacoffee.com/robmllze" target="_blank"><img align="right" src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

Dart & Flutter Packages by DevCetra.com & contributors.

[![Pub Package](https://img.shields.io/pub/v/df_pod.svg)](https://pub.dev/packages/df_pod)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg)](https://raw.githubusercontent.com/robmllze/df_pod/main/LICENSE)

---

## Summary

This package provides tools for managing app state using ValueNotifier-like objects called Pods (an acronym for "Points of Data"). For a practical demonstration of how Pods work in conjunction with [GetIt](https://pub.dev/packages/get_it) for state management, refer to [this example](https://pub.dev/packages/df_pod/example). For a full feature set, please refer to the [API reference](https://pub.dev/documentation/df_pod/).

## Quickstart

```dart
// Define a Pod, similar to how you would define a ValueNotifier.
final pNumbers = Pod<List<int>>([1, 2, 3, 4, 5]);

// Use the Pod in your UI, similar to a ValueListenableBuilder.
PodBuilder(
  pod: pNumbers,
  builder: (context, numbers, child) {
    return Text('Count: ${numbers.length}');
  },
);

// Set a Pod with the set function. This will trigger PodBuilder to rebuild.
pNumbers.set([1, 2, 4]);

// Update a pod with the update function. This will also trigger PodBuilder to rebuild.
pNumbers.update((e) => e..add(5));

// Dispose of Pods when they are no longer needed.
pNumbers.dispose();

// If the Pod<T> type T is a primitive type or implements an Equatable, the PodBuilder will only rebuild if the Pod's value actually changed.
final pHelloWorld = Pod('Hello World');
pHelloWorld.set('Hello World'); // this will not trigger a rebuild, as String is a primitive, pass-by-value type.

// A Pod can be transformed into a ChildPod using the map function.
final pLength = pNumbers.map((e) => e!.length);
final ChildPod<List<int>, int> pSum = pNumbers.map((e) => e!.reduce((a, b) => a + b));

// A ChildPod can be further mapped into another ChildPod.
final pInverseLength = pLength.map((e) => 1 / e!);

// ChildPods don't need to be manually disposed; they are disposed automatically when their parent is disposed.
pInverseLength.dispose(); // This will print a warning!

// You can use multiple Pods with a PodListBuilder.
PodListBuilder(
  podList: [pLength, pSum],
  builder: (context, values, child) {
    final [length, sum] = values.toList();
    return Text('Length is $length and sum is $sum');
  },
);

// Pods can also be reduced into a single, ChildPod:
final pZero = pLength.reduce(pInverseLength, (p1, p2) => p1.value * p2.value); // pZero will be disposed if either pLength or pInverseLength is disposed.
```

## Installation

Use this package as a dependency by adding it to your `pubspec.yaml` file (see [here](https://pub.dev/packages/df_pod/install)).

---

## Contributing and Discussions

This is an open-source project, and we warmly welcome contributions from everyone, regardless of experience level. Whether you're a seasoned developer or just starting out, contributing to this project is a fantastic way to learn, share your knowledge, and make a meaningful impact on the community.

### Ways you can contribute:

- **Join the discussions and ask questions:** Your curiosity can lead to valuable insights and improvements.
- **Buy me a coffee:** If you'd like to support the project financially, consider [buying me a coffee](https://www.buymeacoffee.com/robmllze). Your support helps cover the costs of development and keeps the project growing.
- **Share your ideas:** Every perspective matters, and your ideas can spark innovation.
- **Report bugs:** Help us identify and fix issues to make the project more robust.
- **Suggest improvements or new features:** Your ideas can help shape the future of the project.
- **Help clarify documentation:** Good documentation is key to accessibility. You can make it easier for others to get started by improving or expanding our documentation.
- **Write articles:** Share your knowledge by writing tutorials, guides, or blog posts about your experiences with the project. It's a great way to contribute and help others learn.

No matter how you choose to contribute, your involvement is greatly appreciated and valued!

---

### Join Reddit Discussions:

💬 https://www.reddit.com/r/df_pod/

### Join GitHub Discussions:

💬 https://github.com/robmllze/df_pod/discussions/

### Chief Maintainer:

📧 Email _Robert Mollentze_ at robmllze@gmail.com

### Dontations:

If you're enjoying this package and find it valuable, consider showing your appreciation with a small donation. Every bit helps in supporting future development. You can donate here:

https://www.buymeacoffee.com/robmllze

---

## License

This project is released under the MIT License. See [LICENSE](https://raw.githubusercontent.com/robmllze/df_pod/main/LICENSE) for more information.
