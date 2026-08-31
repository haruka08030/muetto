import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../models/localized.dart';
import '../../models/tasting_log.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../log/draft_sync.dart';
import '../log/log_list_controller.dart';
import '../log/rating_stars.dart';

/// ホーム（S-04）。
///
/// 最近のログとコレクションの概要を出す。好み傾向とレコメンドは
/// Phase 3 で足す（docs/screens.md 1）。
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 溜まっている下書きを送る。ホームは必ず通るので、
    // ここに置けば起動専用の画面を作らずに済む。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(draftSyncProvider.notifier).flush();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAnonymous = ref.watch(isAnonymousProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: isAnonymous ? 'やめる' : 'ログアウト',
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
            if (isAnonymous) const _AnonymousNotice(),
            const _PendingDrafts(),
            const _RecentLogs(),
            const SizedBox(height: AppSpacing.lg),
            const _SearchAction(),
          ],
        ),
      ),
    );
  }
}

/// 未送信の下書きがあることを控えめに伝える。
///
/// 警告としては出さない。オフラインであることを意識させないのが
/// 方針で（docs/screens.md 3）、ここで不安にさせても打つ手がない。
class _PendingDrafts extends ConsumerWidget {
  const _PendingDrafts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drafts = ref.watch(draftsProvider);
    final count = drafts.valueOrNull?.length ?? 0;
    if (count == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$count 件を送信待ちです',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => ref.read(draftSyncProvider.notifier).flush(),
            child: const Text('今すぐ送る'),
          ),
        ],
      ),
    );
  }
}

/// 匿名で使っていることを伝える。
///
/// 記録は残るが、この端末のセッションに紐づく。消えては困るものは
/// アカウントを作ってもらう必要がある。
class _AnonymousNotice extends StatelessWidget {
  const _AnonymousNotice();

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
                Text('お試しで使っています', style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '記録は残りますが、この端末だけのものです。\n'
              '残しておきたい場合はアカウントを作ってください。',
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
                  text: 'まだ記録がありません\n＋ボタンから追加できます',
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
