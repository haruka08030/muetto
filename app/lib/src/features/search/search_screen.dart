import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../models/localized.dart';
import '../../models/perfume.dart';
import '../../theme/app_theme.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(searchControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final notifier = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'ブランド名・香水名で検索',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: state.query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      notifier.updateQuery('');
                    },
                  ),
          ),
          onChanged: notifier.updateQuery,
          onSubmitted: (_) => notifier.run(),
        ),
      ),
      body: _body(context, state),
    );
  }

  Widget _body(BuildContext context, SearchState state) {
    if (state.error != null) {
      return _Message(
        icon: Icons.error_outline,
        title: '検索できませんでした',
        detail: '${state.error}',
        action: FilledButton(
          onPressed: ref.read(searchControllerProvider.notifier).run,
          child: const Text('やり直す'),
        ),
      );
    }

    if (state.isPristine) {
      return const _Message(
        icon: Icons.local_florist_outlined,
        title: '香水を探す',
        detail: 'ブランド名や香水名を入力してください。\n多少の綴り違いでも見つかります。',
      );
    }

    if (state.results.isEmpty) {
      return _Message(
        icon: Icons.search_off,
        title: '見つかりませんでした',
        detail: '「${state.query}」に一致する香水がありません。',
        // 店頭で行き止まりにしない。未登録の香水はその場で登録できるようにする。
        action: OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('香水の新規登録は Phase 5 で追加します')),
          ),
          icon: const Icon(Icons.add),
          label: const Text('この香水を登録する'),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: state.results.length + (state.isLoading ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        if (index >= state.results.length) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _PerfumeTile(perfume: state.results[index]);
      },
    );
  }
}

class _PerfumeTile extends StatelessWidget {
  const _PerfumeTile({required this.perfume});

  final PerfumeSummary perfume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final concentration = concentrationLabel(perfume.concentration);
    final subtitle = [
      localizedName(nameEn: perfume.brandNameEn, nameJa: perfume.brandNameJa),
      if (concentration.isNotEmpty) concentration,
      if (perfume.releaseYear != null) '${perfume.releaseYear}',
    ].join(' · ');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundImage: perfume.imageUrl == null
            ? null
            : NetworkImage(perfume.imageUrl!),
        child: const Icon(Icons.water_drop_outlined),
      ),
      title: Text(
        localizedName(nameEn: perfume.nameEn, nameJa: perfume.nameJa),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      // 未検証データであることを隠さない。ユーザーが情報の確度を判断できるようにする。
      trailing: perfume.isVerified
          ? null
          : Tooltip(
              message: '情報が未確認です',
              child: Icon(
                Icons.help_outline,
                size: 18,
                color: theme.colorScheme.outline,
              ),
            ),
      onTap: () => context.push('${Routes.perfume}/${perfume.id}'),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
