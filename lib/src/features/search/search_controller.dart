import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/perfume_repository.dart';
import '../../models/perfume.dart';

class SearchState {
  const SearchState({
    this.query = '',
    this.filters = const SearchFilters(),
    this.results = const [],
    this.isLoading = false,
    this.hasMore = false,
    this.error,
  });

  final String query;
  final SearchFilters filters;
  final List<PerfumeSummary> results;
  final bool isLoading;
  final bool hasMore;
  final Object? error;

  /// 何も入力・選択されていない初期状態か。
  bool get isPristine => query.trim().isEmpty && filters.isEmpty;

  SearchState copyWith({
    String? query,
    SearchFilters? filters,
    List<PerfumeSummary>? results,
    bool? isLoading,
    bool? hasMore,
    Object? error,
    bool clearError = false,
  }) => SearchState(
    query: query ?? this.query,
    filters: filters ?? this.filters,
    results: results ?? this.results,
    isLoading: isLoading ?? this.isLoading,
    hasMore: hasMore ?? this.hasMore,
    error: clearError ? null : (error ?? this.error),
  );
}

const _pageSize = 30;

class SearchController extends Notifier<SearchState> {
  Timer? _debounce;

  /// 入力のたびに投げると、店頭の電波が悪い環境で無駄な往復が増える。
  static const debounceDuration = Duration(milliseconds: 350);

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchState();
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    if (state.isPristine) {
      state = state.copyWith(results: [], hasMore: false, clearError: true);
      return;
    }
    _debounce = Timer(debounceDuration, run);
  }

  void updateFilters(SearchFilters filters) {
    state = state.copyWith(filters: filters);
    _debounce?.cancel();
    if (state.isPristine) {
      state = state.copyWith(results: [], hasMore: false, clearError: true);
      return;
    }
    unawaited(run());
  }

  Future<void> run() async {
    if (state.isPristine) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await ref
          .read(perfumeRepositoryProvider)
          .search(query: state.query, filters: state.filters, limit: _pageSize);
      state = state.copyWith(
        results: results,
        isLoading: false,
        hasMore: results.length == _pageSize,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final more = await ref
          .read(perfumeRepositoryProvider)
          .search(
            query: state.query,
            filters: state.filters,
            limit: _pageSize,
            offset: state.results.length,
          );
      state = state.copyWith(
        results: [...state.results, ...more],
        isLoading: false,
        hasMore: more.length == _pageSize,
      );
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error);
    }
  }
}

final searchControllerProvider =
    NotifierProvider<SearchController, SearchState>(SearchController.new);
