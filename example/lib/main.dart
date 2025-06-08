import 'package:df_pod/df_pod.dart';
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
  await Future<void>.delayed(const Duration(milliseconds: 800)); // Simulate network latency

  if (query.toLowerCase() == 'error') {
    throw Exception('Network failed. Please try again.');
  }
  if (query.isEmpty) {
    return Pod([]);
  }
  final results = mockProducts.where((p) => p.toLowerCase().contains(query.toLowerCase())).toList();
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
    // PodListBuilder efficiently listens to multiple pods and rebuilds if any of them change.
    return PodListBuilder(
      podList: [pResultCount, pSummaryMessage],
      builder: (context, snapshot) {
        final values = snapshot.value.unwrap().map((e) => e.unwrap()).toList();
        final count = values[0] as int;
        final message = values[1] as String;
        return Card(
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '[$count]: $message',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
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
        final query = querySnapshot.value.unwrap().unwrap();

        if (query.isEmpty) {
          return const Center(child: Icon(Icons.search, size: 64, color: Colors.grey));
        }

        // The inner PodBuilder handles the async search operation.
        return PodBuilder<List<String>>(
          // A ValueKey ensures the cache is tied to a specific query.
          key: ValueKey(query),
          pod: searchApi(query),
          // Cache successful results for 2 minutes.
          cacheDuration: const Duration(minutes: 2),
          builder: (context, resultsSnapshot) {
            // 1. Handle the Option layer: Loading vs. Available
            if (resultsSnapshot.value.isNone()) {
              return const Center(child: CircularProgressIndicator());
            }

            final result = resultsSnapshot.value.unwrap();

            // 2. Handle the Result layer: Success vs. Failure
            if (result.isErr()) {
              final error = result.err().unwrap().error;
              return Center(
                child: Text('An error occurred: $error', style: const TextStyle(color: Colors.red)),
              );
            }

            final products = result.unwrap();
            // Update our root pod with the latest successful results
            pLatestResults.set(products);

            if (products.isEmpty) {
              return Center(child: Text('No results found for "$query"'));
            }

            return ListView.builder(
              itemCount: products.length,
              itemBuilder:
                  (_, index) => ListTile(
                    leading: const Icon(Icons.shopping_bag_outlined),
                    title: Text(products[index]),
                  ),
            );
          },
        );
      },
    );
  }
}
