import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_repository.dart';
import '../../data/perfume_repository.dart';
import '../../models/localized.dart';
import '../../models/perfume.dart';
import '../../theme/app_theme.dart';
import '../collection/add_actions.dart';
import '../collection/collection_controller.dart';
import 'add_action_sheet.dart';
import 'log_form_screen.dart';

/// 追加する香水を選ぶ（中央 FAB の行き先）。
///
/// 選んだあとに、試した・持ってる・欲しいのどれかを尋ねる。
/// 検索画面とは別に持つ。あちらは「調べる」、ここは「追加する対象を決める」で、
/// 選んだあとの行き先が違う。
class PickPerfumeScreen extends ConsumerStatefulWidget {
  const PickPerfumeScreen({super.key});

  @override
  ConsumerState<PickPerfumeScreen> createState() => _PickPerfumeScreenState();
}

class _PickPerfumeScreenState extends ConsumerState<PickPerfumeScreen> {
  final _query = TextEditingController();
  List<PerfumeSummary> _results = const [];
  bool _isLoading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    // 何も打たないうちから候補を出す。店頭で 1 タップでも減らすため。
    _search('');
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await ref
          .read(perfumeRepositoryProvider)
          .search(query: query, limit: 30);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  /// 香水を選んだら、何をするかを尋ねてから進む。
  Future<void> _pick(PerfumeSummary perfume) async {
    final name = localizedName(nameEn: perfume.nameEn, nameJa: perfume.nameJa);
    final action = await showAddActionSheet(context, name);
    if (action == null || !mounted) {
      return;
    }

    final added = switch (action) {
      AddAction.tasted => await _openLogForm(perfume),
      AddAction.owned => await _addToCollection(perfume),
      AddAction.wanted => await _addToWishlist(perfume),
    };

    if (!added || !mounted) {
      return;
    }
    await Navigator.of(context).maybePop();
  }

  Future<bool> _openLogForm(PerfumeSummary perfume) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => LogFormScreen(perfume: perfume),
      ),
    );
    return saved ?? false;
  }

  Future<bool> _addToCollection(PerfumeSummary perfume) async {
    final input = await showModalBottomSheet<CollectionInput>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CollectionSheet(),
    );
    if (input == null) {
      return false;
    }

    try {
      await ref
          .read(collectionRepositoryProvider)
          .addItem(
            perfumeId: perfume.id,
            acquisitionType: input.type,
            volumeMl: input.volumeMl,
          );
      ref.invalidate(collectionItemsProvider);
      _toast('コレクションに追加しました');
      return true;
    } on Object catch (error) {
      _toast('追加できませんでした: $error');
      return false;
    }
  }

  Future<bool> _addToWishlist(PerfumeSummary perfume) async {
    final priority = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => const PrioritySheet(),
    );
    if (priority == null) {
      return false;
    }

    try {
      await ref
          .read(collectionRepositoryProvider)
          .addToWishlist(perfumeId: perfume.id, priority: priority);
      ref.invalidate(wishlistProvider);
      _toast('欲しいものに追加しました');
      return true;
    } on Object catch (error) {
      _toast('追加できませんでした: $error');
      return false;
    }
  }

  void _toast(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('追加する')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _query,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'ブランド名・香水名で探す',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _query.clear();
                          _search('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_isLoading && _results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _Message(text: '読み込めませんでした\n$_error');
    }
    if (_results.isEmpty) {
      return const _Message(text: '見つかりませんでした');
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final perfume = _results[index];
        return ListTile(
          title: Text(
            localizedName(nameEn: perfume.nameEn, nameJa: perfume.nameJa),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            localizedName(
              nameEn: perfume.brandNameEn,
              nameJa: perfume.brandNameJa,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _pick(perfume),
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
