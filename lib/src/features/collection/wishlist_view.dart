import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_repository.dart';
import '../../models/collection.dart';
import '../../models/localized.dart';
import '../../theme/app_theme.dart';
import 'collection_controller.dart';

/// 気になっている香水の一覧（S-12）。
///
/// 優先度の高い順に並べる。「次に何を試すか」を決めるための画面なので、
/// 迷ったときに上から見れば済むようにする。
class WishlistView extends ConsumerWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(wishlistProvider);

    return items.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _Notice(icon: Icons.cloud_off_outlined, text: '読み込めませんでした\n$error'),
      data: (list) => list.isEmpty
          ? const _Notice(
              icon: Icons.favorite_outline,
              text: '気になる香水がありません\n香水詳細から追加できます',
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(wishlistProvider),
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) => _WishTile(item: list[index]),
              ),
            ),
    );
  }
}

class _WishTile extends ConsumerWidget {
  const _WishTile({required this.item});

  final WishlistItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final memo = item.memo?.trim();

    return Dismissible(
      key: ValueKey(item.id),
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
      onDismissed: (direction) async {
        await ref
            .read(collectionRepositoryProvider)
            .deleteWishlistItem(item.id);
        ref.invalidate(wishlistProvider);
      },
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
            _PriorityDots(priority: item.priority),
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
}

/// 優先度。星と紛らわしくないよう、評価とは違う形にする。
class _PriorityDots extends StatelessWidget {
  const _PriorityDots({required this.priority});

  final int priority;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= priority
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
              ),
            ),
          ),
      ],
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
