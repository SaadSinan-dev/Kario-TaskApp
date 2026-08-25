import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/app/providers.dart';
import 'package:kairo/app/session.dart';
import 'package:kairo/domain/repositories/repositories.dart';

/// Search state.
///
/// The debounce lives in the input widget (`AppSearchField`), so this provider
/// only ever sees settled queries — which keeps the async provider from
/// thrashing and makes the loading state meaningful.
class SearchQueryController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;

  void clear() => state = '';
}

final NotifierProvider<SearchQueryController, String> searchQueryProvider =
    NotifierProvider<SearchQueryController, String>(SearchQueryController.new);

final FutureProvider<List<SearchHit>> searchResultsProvider =
    FutureProvider<List<SearchHit>>((Ref ref) async {
      final String query = ref.watch(searchQueryProvider).trim();
      final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (query.isEmpty || workspaceId == null) return const <SearchHit>[];

      final List<SearchHit> hits = await ref
          .watch(searchRepositoryProvider)
          .search(workspaceId, query);

      // Remember only queries that produced something — a typo is not history.
      if (hits.isNotEmpty) {
        await ref.read(searchRepositoryProvider).rememberQuery(query);
      }
      return hits;
    });

final FutureProvider<List<String>> recentQueriesProvider =
    FutureProvider<List<String>>(
      (Ref ref) => ref.watch(searchRepositoryProvider).recentQueries(),
    );

final FutureProvider<List<SearchHit>> recentlyViewedProvider =
    FutureProvider<List<SearchHit>>((Ref ref) {
      final String? workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return Future<List<SearchHit>>.value(const <SearchHit>[]);
      }
      return ref.watch(searchRepositoryProvider).recentlyViewed(workspaceId);
    });
