import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/perfume_repository.dart';
import '../../models/localized.dart';
import '../../models/perfume.dart';
import '../../theme/app_theme.dart';
import 'log_form_screen.dart';

/// ログを書く香水を選ぶ（S-08 の入口）。
///
/// 中央 FAB から来る。ここで選んでから評価を付ける。
/// 検索画面とは別に持つ。あちらは「調べる」、ここは「記録する対象を決める」で、
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

  Future<void> _openForm(PerfumeSummary perfume) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => LogFormScreen(perfume: perfume),
      ),
    );

    if (saved ?? false) {
      if (!mounted) return;
      await Navigator.of(context).maybePop();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('ログを保存しました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログを書く')),
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
          onTap: () => _openForm(perfume),
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
