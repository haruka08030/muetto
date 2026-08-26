import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/supabase.dart';
import '../models/perfume.dart';

/// 検索の絞り込み条件。
class SearchFilters {
  const SearchFilters({
    this.noteIds = const [],
    this.accordIds = const [],
    this.concentrations = const [],
    this.includeUnverified = true,
  });

  final List<String> noteIds;
  final List<String> accordIds;
  final List<String> concentrations;
  final bool includeUnverified;

  bool get isEmpty =>
      noteIds.isEmpty && accordIds.isEmpty && concentrations.isEmpty;

  int get activeCount =>
      noteIds.length + accordIds.length + concentrations.length;

  SearchFilters copyWith({
    List<String>? noteIds,
    List<String>? accordIds,
    List<String>? concentrations,
    bool? includeUnverified,
  }) => SearchFilters(
    noteIds: noteIds ?? this.noteIds,
    accordIds: accordIds ?? this.accordIds,
    concentrations: concentrations ?? this.concentrations,
    includeUnverified: includeUnverified ?? this.includeUnverified,
  );
}

class PerfumeRepository {
  const PerfumeRepository();

  /// 検索。並び順とスコアリングは DB 側の search_perfumes に持たせている。
  /// クライアントで再ソートしないこと（検証済み優先の順序が崩れる）。
  Future<List<PerfumeSummary>> search({
    String? query,
    SearchFilters filters = const SearchFilters(),
    int limit = 30,
    int offset = 0,
  }) async {
    final rows = await supabase.rpc<List<dynamic>>(
      'search_perfumes',
      params: {
        'q': (query == null || query.trim().isEmpty) ? null : query.trim(),
        if (filters.noteIds.isNotEmpty) 'note_ids': filters.noteIds,
        if (filters.accordIds.isNotEmpty) 'accord_ids': filters.accordIds,
        if (filters.concentrations.isNotEmpty)
          'concentrations': filters.concentrations,
        'include_unverified': filters.includeUnverified,
        'max_results': limit,
        'skip': offset,
      },
    );
    return rows
        .cast<Map<String, dynamic>>()
        .map(PerfumeSummary.fromJson)
        .toList();
  }

  Future<PerfumeDetail> detail(String perfumeId) async {
    final perfume = await supabase
        .from('perfumes')
        .select(
          'id, name_en, name_ja, concentration, release_year, image_url, '
          'is_verified, perfumer, brands!inner(id, name_en, name_ja)',
        )
        .eq('id', perfumeId)
        .single();

    final brand = perfume['brands'] as Map<String, dynamic>;
    final summary = PerfumeSummary.fromJson({
      ...perfume,
      'brand_name_en': brand['name_en'],
      'brand_name_ja': brand['name_ja'],
    });

    final noteRows = await supabase.rpc<List<dynamic>>(
      'perfume_note_pyramid',
      params: {'target': perfumeId},
    );
    final accordRows = await supabase.rpc<List<dynamic>>(
      'perfume_accord_bars',
      params: {'target': perfumeId},
    );

    return PerfumeDetail(
      summary: summary,
      perfumer: perfume['perfumer'] as String?,
      notes: noteRows
          .cast<Map<String, dynamic>>()
          .map(PerfumeNote.fromJson)
          .toList(),
      accords: accordRows
          .cast<Map<String, dynamic>>()
          .map(PerfumeAccord.fromJson)
          .toList(),
    );
  }
}

final perfumeRepositoryProvider = Provider<PerfumeRepository>(
  (ref) => const PerfumeRepository(),
);

final perfumeDetailProvider = FutureProvider.family<PerfumeDetail, String>(
  (ref, id) => ref.watch(perfumeRepositoryProvider).detail(id),
);
