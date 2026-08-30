import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_repository.dart';
import '../../models/collection.dart';
import '../../models/localized.dart';
import '../../theme/app_theme.dart';
import 'collection_controller.dart';

/// 持っている香水の一覧（S-10）。
class CollectionItemsView extends ConsumerWidget {
  const CollectionItemsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(collectionItemsProvider);
    final filter = ref.watch(collectionFilterProvider);

    return Column(
      children: [
        _StatusFilter(current: filter),
        Expanded(
          child: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _Notice(
              icon: Icons.cloud_off_outlined,
              text: '読み込めませんでした\n$error',
            ),
            data: (list) => list.isEmpty
                ? const _Notice(
                    icon: Icons.style_outlined,
                    text: '登録した香水がありません\n香水詳細から追加できます',
                  )
                : RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(collectionItemsProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: list.length,
                      itemBuilder: (context, index) =>
                          _ItemCard(item: list[index]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _StatusFilter extends ConsumerWidget {
  const _StatusFilter({required this.current});

  final CollectionStatus? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          _chip(ref, label: 'すべて', value: null),
          for (final status in CollectionStatus.values)
            _chip(ref, label: status.label, value: status),
        ],
      ),
    );
  }

  Widget _chip(
    WidgetRef ref, {
    required String label,
    required CollectionStatus? value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: current == value,
        onSelected: (_) =>
            ref.read(collectionFilterProvider.notifier).set(value),
      ),
    );
  }
}

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Row(
              children: [
                Expanded(
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
                    ],
                  ),
                ),
                _Menu(item: item),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _RemainingBar(item: item),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                _Tag(text: item.acquisitionType.label),
                if (item.status != CollectionStatus.active) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _Tag(text: item.status.label),
                ],
                const Spacer(),
                TextButton(
                  onPressed: () => _editRemaining(context, ref),
                  child: const Text('残量を更新'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editRemaining(BuildContext context, WidgetRef ref) async {
    final updated = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RemainingSheet(initial: item.remainingPct),
    );
    if (updated == null) {
      return;
    }

    await ref
        .read(collectionRepositoryProvider)
        .updateRemaining(itemId: item.id, remainingPct: updated);
    ref.invalidate(collectionItemsProvider);
  }
}

/// 残量。数字だけより、減っていくのが見えるほうが分かりやすい。
class _RemainingBar extends StatelessWidget {
  const _RemainingBar({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remainingMl = item.remainingMl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.remainingPct / 100,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          remainingMl == null
              ? '残り ${item.remainingPct}%'
              : '残り ${item.remainingPct}%（約 ${remainingMl.toStringAsFixed(0)} ml）',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RemainingSheet extends StatefulWidget {
  const _RemainingSheet({required this.initial});

  final int initial;

  @override
  State<_RemainingSheet> createState() => _RemainingSheetState();
}

class _RemainingSheetState extends State<_RemainingSheet> {
  late double _value = widget.initial.toDouble();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('残量', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${_value.round()}%',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            Slider(
              value: _value,
              max: 100,
              divisions: 20,
              label: '${_value.round()}%',
              onChanged: (value) => setState(() => _value = value),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_value.round()),
              child: const Text('更新する'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Menu extends ConsumerWidget {
  const _Menu({required this.item});

  final CollectionItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<CollectionStatus>(
      icon: const Icon(Icons.more_vert),
      onSelected: (status) async {
        await ref
            .read(collectionRepositoryProvider)
            .updateStatus(itemId: item.id, status: status);
        ref.invalidate(collectionItemsProvider);
      },
      itemBuilder: (context) => [
        for (final status in CollectionStatus.values)
          if (status != item.status)
            PopupMenuItem(value: status, child: Text('${status.label}にする')),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(text, style: theme.textTheme.labelSmall),
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
