import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/tasting_log_repository.dart';
import '../../models/localized.dart';
import '../../models/tasting_log.dart';
import '../../theme/app_theme.dart';
import 'log_list_controller.dart';
import 'rating_stars.dart';

/// 試香ログの一覧（S-09）の中身。
///
/// コレクションの内タブに置くので、AppBar は外側が持つ。
/// 並び順の切り替えは一覧の上に小さく出す。
class LogListView extends ConsumerWidget {
  const LogListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logListProvider);
    final sort = ref.watch(logSortProvider);

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: TextButton.icon(
              icon: const Icon(Icons.sort, size: 18),
              label: Text(sort.label),
              onPressed: () => _pickSort(context, ref, sort),
            ),
          ),
        ),
        Expanded(child: _body(context, ref, logs)),
      ],
    );
  }

  Future<void> _pickSort(
    BuildContext context,
    WidgetRef ref,
    LogSort current,
  ) async {
    final picked = await showModalBottomSheet<LogSort>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in LogSort.values)
              ListTile(
                title: Text(option.label),
                trailing: option == current ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      ref.read(logSortProvider.notifier).set(picked);
    }
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TastingLogWithPerfume>> logs,
  ) {
    return logs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Message(
          icon: Icons.error_outline,
          text: '読み込めませんでした\n$error',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _Message(
              icon: Icons.edit_note_outlined,
              text: 'まだログがありません\n＋ボタンから最初の記録を書けます',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(logListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) => _LogTile(item: items[index]),
            ),
          );
      },
    );
  }
}

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.item});

  final TastingLogWithPerfume item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final log = item.log;
    final memo = log.memo?.trim();

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: theme.colorScheme.errorContainer,
        child: Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
      ),
      confirmDismiss: (direction) => _confirmDelete(context),
      onDismissed: (direction) => _delete(ref),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        title: Text(
          localizedName(
            nameEn: item.perfume.nameEn,
            nameJa: item.perfume.nameJa,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xs),
            Text(
              localizedName(
                nameEn: item.perfume.brandNameEn,
                nameJa: item.perfume.brandNameJa,
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                RatingStarsDisplay(rating: log.rating),
                const SizedBox(width: AppSpacing.md),
                Text(
                  _formatDate(log.testedAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (log.wantToBuy) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ],
            ),
            if (memo != null && memo.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                memo,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('このログを削除しますか'),
        content: const Text('元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _delete(WidgetRef ref) async {
    await ref.read(tastingLogRepositoryProvider).delete(item.log.id);
    ref.invalidate(logListProvider);
  }

  /// 一覧では年を省く。同じ年のログばかり並ぶため。
  static String _formatDate(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year
        ? '${value.month}/${value.day}'
        : '${value.year}/${value.month}/${value.day}';
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
