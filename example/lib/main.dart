import 'package:df_pod/df_pod.dart';
import 'package:df_safer_dart/df_safer_dart.dart';
import 'package:flutter/material.dart';

// ===================================================================
// 1. MOCK DATA & API
// ===================================================================

const mockProducts = [
  'Flux Capacitor',
  'Hoverboard',
  'Self-Lacing Shoes',
  'Time Machine',
  'Fusion Reactor',
  'Power Laces',
  'Sports Almanac',
  'DeLorean',
];

/// Simulates a network API call to search for products.
/// It can either succeed with a `Pod<List<String>>` or fail with an exception.
Future<Pod<List<String>>> searchApi(String query) async {
  await Future<void>.delayed(
    const Duration(milliseconds: 800),
  ); // Simulate network latency

  if (query.toLowerCase() == 'error') {
    throw Exception('Network failed. Please try again.');
  }
  if (query.isEmpty) {
    return Pod([]);
  }
  final results = mockProducts
      .where((p) => p.toLowerCase().contains(query.toLowerCase()))
      .toList();
  return Pod(results);
}

// ===================================================================
// 2. DEFINING & COMPOSING PODS
// ===================================================================

// --- Root Pod ---
/// A root pod holding the current search query from the user.
final pSearchQuery = Pod('');

// --- Derived Pods (ChildPod & ReducerPod) ---

// This pod is special: it holds the *result* of our async search.
// It's a Pod that contains another Pod, representing the latest successful search.
final pLatestResults = Pod<List<String>>([]);

/// A `ChildPod` that derives the result count by mapping `pLatestResults`.
/// It maps from a `List<String>` to an `int`.
final pResultCount = pLatestResults.map((results) => results.length);

/// A `ReducerPod` that combines the result count and search query
/// to create a dynamic summary message. It updates if either parent changes.
final pSummaryMessage = pResultCount.reduce(pSearchQuery, (count, query) {
  if (query.getValue().isEmpty) return 'Enter a search term.';
  if (count.getValue() == 0) return 'No results found.';
  return 'Found ${count.getValue()} result(s) for "${query.getValue()}".';
});

// ===================================================================
// 3. BUILDING THE UI
// ===================================================================

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'df_pod Comprehensive Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ProductSearchScreen(),
    );
  }
}

class ProductSearchScreen extends StatelessWidget {
  const ProductSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Search')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            SearchField(),
            SizedBox(height: 12),
            // Use PodListBuilder for an efficient summary view
            SearchSummary(),
            Divider(height: 32),
            Expanded(child: SearchResults()),
          ],
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (query) => pSearchQuery.set(query),
      decoration: const InputDecoration(
        labelText: 'Search for a product (or type "error")',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.search),
      ),
    );
  }
}

class SearchSummary extends StatelessWidget {
  const SearchSummary({super.key});

  @override
  Widget build(BuildContext context) {
    // PodListBuilder efficiently listens to multiple pods and rebuilds if
    // any of them change.
    return PodListBuilder(
      podList: [pResultCount, pSummaryMessage],
      builder: (context, snapshot) {
        // snapshot.value: Option<Iterable<Option<Result<Object>>>>
        //
        // Destructure with Dart 3 sealed-class patterns. The
        // `final int v` / `final String v` bindings act as type guards —
        // the arm only matches when the inner value has the expected
        // runtime type, so we avoid `.unwrap()` and `as`. Falling
        // through to the wildcard arm returns an empty widget instead
        // of throwing.
        final entries = switch (snapshot.value) {
          Some(value: final list) => list.toList(),
          None() => const <Option<Result<Object>>>[],
        };
        if (entries.length < 2) return const SizedBox.shrink();
        final count = switch (entries[0]) {
          Some(value: Ok(value: final int v)) => v,
          _ => null,
        };
        final message = switch (entries[1]) {
          Some(value: Ok(value: final String v)) => v,
          _ => null,
        };
        if (count == null || message == null) {
          return const SizedBox.shrink();
        }
        return Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '[$count]: $message',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        );
      },
    );
  }
}

class SearchResults extends StatelessWidget {
  const SearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    // This builder listens to the search query pod.
    return PodBuilder<String>(
      pod: pSearchQuery,
      // Debounce user input to avoid firing the API on every keystroke.
      debounceDuration: const Duration(milliseconds: 400),
      builder: (context, querySnapshot) {
        // Destructure Option<Result<String>> via patterns. No `unwrap()`,
        // no `as` — the pattern's `final String v` doubles as a type
        // guard, so the empty-string fallback only fires on None / Err /
        // unexpected type.
        final query = switch (querySnapshot.value) {
          Some(value: Ok(value: final String v)) => v,
          _ => '',
        };

        if (query.isEmpty) {
          return const Center(
            child: Icon(Icons.search, size: 64, color: Colors.grey),
          );
        }

        // The inner PodBuilder handles the async search operation.
        return PodBuilder<List<String>>(
          // A ValueKey ensures the cache is tied to a specific query.
          key: ValueKey(query),
          pod: searchApi(query),
          // Cache successful results for 2 minutes.
          cacheDuration: const Duration(minutes: 2),
          builder: (context, resultsSnapshot) {
            // Three-state switch: loading / success / failure. Each
            // arm gets exactly the data it needs via destructuring —
            // no defensive unwraps, no casts. The Object generic on
            // `error` is the type from `Err.error`; we render its
            // toString() for the UI.
            return switch (resultsSnapshot.value) {
              None() => const Center(child: CircularProgressIndicator()),
              Some(value: Err(:final error)) => Center(
                child: Text(
                  'An error occurred: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              Some(value: Ok(value: final products)) =>
                _buildProductList(query, products),
            };
          },
        );
      },
    );
  }

  /// Renders the product list and side-effects the latest-results pod.
  /// Extracted so the switch arm above stays a clean expression.
  Widget _buildProductList(String query, List<String> products) {
    pLatestResults.set(products);
    if (products.isEmpty) {
      return Center(child: Text('No results found for "$query"'));
    }
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (_, index) => ListTile(
        leading: const Icon(Icons.shopping_bag_outlined),
        title: Text(products[index]),
      ),
    );
  }
}
