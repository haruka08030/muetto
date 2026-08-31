import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';

import '../../data/perfume_repository.dart';
import '../../models/localized.dart';
import '../../models/perfume.dart';
import '../../theme/app_theme.dart';

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

  /// 香水を選んだら詳細へ渡す。そこに試した・持ってる・欲しいがある。
  ///
  /// ここで何をするかを尋ねない。先に製品を見てから決めたいことが多く、
  /// 選んだ直後に問うと、確かめる前に決めさせることになる。
  void _open(PerfumeSummary perfume) {
    context.push('${Routes.log}/${Routes.perfume}/${perfume.id}');
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
          onTap: () => _open(perfume),
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
