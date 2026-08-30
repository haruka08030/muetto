import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../models/localized.dart';
import '../../models/tasting_log.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../log/log_list_controller.dart';
import '../log/rating_stars.dart';

/// ホーム（S-04）。
///
/// 最近のログとコレクションの概要を出す。好み傾向とレコメンドは
/// Phase 3 で足す（docs/screens.md 1）。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(guestModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: isGuest ? 'ゲスト閲覧をやめる' : 'ログアウト',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(recentLogsProvider),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (isGuest) const _GuestNotice() else const _RecentLogs(),
            const SizedBox(height: AppSpacing.lg),
            const _SearchAction(),
          ],
        ),
      ),
    );
  }
}

/// ゲストには記録が無い。何ができるかだけ伝える。
class _GuestNotice extends StatelessWidget {
  const _GuestNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: AppShapes.card,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('ゲストとして閲覧中', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '香水を探して詳細を見られます。\n'
              '試香の記録を残すにはログインしてください。',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// 直近の試香ログ。ここが埋まっていくのがこのアプリの手応えになる。
class _RecentLogs extends ConsumerWidget {
  const _RecentLogs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(recentLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('最近の記録', style: Theme.of(context).textTheme.titleMedium),
            logs.maybeWhen(
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : TextButton(
                      onPressed: () => StatefulNavigationShell.of(
                        context,
                      ).goBranch(Tabs.collection),
                      child: const Text('すべて見る'),
                    ),
              orElse: SizedBox.shrink,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        logs.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          // ホームで赤いエラーを出しても仕方がない。控えめに伝える。
          error: (error, _) => const _Notice(
            icon: Icons.cloud_off_outlined,
            text: '記録を読み込めませんでした',
          ),
          data: (items) => items.isEmpty
              ? const _Notice(
                  icon: Icons.edit_note_outlined,
                  text: 'まだ記録がありません\n＋ボタンから最初の一件を書けます',
                )
              : Column(
                  children: [
                    for (final item in items) _RecentLogCard(item: item),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RecentLogCard extends StatelessWidget {
  const _RecentLogCard({required this.item});

  final TastingLogWithPerfume item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: AppShapes.card,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizedName(
                nameEn: item.perfume.nameEn,
                nameJa: item.perfume.nameJa,
              ),
              style: theme.textTheme.titleSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              localizedName(
                nameEn: item.perfume.brandNameEn,
                nameJa: item.perfume.brandNameJa,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            RatingStarsDisplay(rating: item.log.rating),
          ],
        ),
      ),
    );
  }
}

class _SearchAction extends StatelessWidget {
  const _SearchAction();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      // 検索はタブなので、ホームの上に積まず検索タブへ移す。
      // push すると下のタブバーの選択と食い違う。
      onPressed: () =>
          StatefulNavigationShell.of(context).goBranch(Tabs.search),
      icon: const Icon(Icons.search),
      label: const Text('香水を探す'),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            text,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
