import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/perfume_repository.dart';
import '../../models/localized.dart';
import '../../models/perfume.dart';
import '../../theme/accord_colors.dart';
import '../../theme/app_theme.dart';
import '../collection/add_actions.dart';

class PerfumeDetailScreen extends ConsumerWidget {
  const PerfumeDetailScreen({required this.perfumeId, super.key});

  final String perfumeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(perfumeDetailProvider(perfumeId));

    return Scaffold(
      appBar: AppBar(title: const Text('香水詳細')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: AppSpacing.md),
                Text('$error', textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(perfumeDetailProvider(perfumeId)),
                  child: const Text('やり直す'),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _Content(detail: data, perfumeId: perfumeId),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.detail, required this.perfumeId});

  final PerfumeDetail detail;
  final String perfumeId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = detail.summary;
    final concentration = concentrationLabel(p.concentration);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          localizedName(nameEn: p.brandNameEn, nameJa: p.brandNameJa),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          localizedName(nameEn: p.nameEn, nameJa: p.nameJa),
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.md),
        AddToCollectionActions(perfume: p),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            if (concentration.isNotEmpty) _Chip(label: concentration),
            if (p.releaseYear != null) _Chip(label: '${p.releaseYear}年'),
            if (detail.perfumer != null) _Chip(label: '調香: ${detail.perfumer}'),
          ],
        ),

        if (!p.isVerified) ...[
          const SizedBox(height: AppSpacing.md),
          const _UnverifiedBanner(),
        ],

        if (detail.accords.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const _SectionTitle('香調'),
          const SizedBox(height: AppSpacing.sm),
          ...detail.accords.map((a) => _AccordBar(accord: a)),
        ],

        if (detail.notes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const _SectionTitle('ノートピラミッド'),
          const SizedBox(height: AppSpacing.sm),
          _NotePyramid(detail: detail),
        ],

        const SizedBox(height: AppSpacing.xl),
        Text(
          '試香ログ・好み適合度・購入導線は Phase 2 以降で追加します。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NotePyramid extends StatelessWidget {
  const _NotePyramid({required this.detail});

  final PerfumeDetail detail;

  static const _labels = {
    'top': 'トップ',
    'middle': 'ミドル',
    'base': 'ラスト',
    'unspecified': 'その他',
  };

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[];
    for (final position in _labels.keys) {
      final notes = detail.notesAt(position);
      if (notes.isEmpty) {
        continue;
      }
      sections.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _labels[position]!,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: notes
                    .map(
                      (n) => _Chip(
                        label: localizedName(
                          nameEn: n.nameEn,
                          nameJa: n.nameJa,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections,
    );
  }
}

class _AccordBar extends StatelessWidget {
  const _AccordBar({required this.accord});

  final PerfumeAccord accord;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 香調の色は検索フィルタ・詳細・分析グラフで共通（docs/screens.md 6）。
    final color = isDark
        ? AccordColors.onDark(accord.slug)
        : AccordColors.of(accord.slug);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              localizedName(nameEn: accord.nameEn, nameJa: accord.nameJa),
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: LinearProgressIndicator(
                value: accord.strength.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnverifiedBanner extends StatelessWidget {
  const _UnverifiedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'この香水の情報はまだ確認されていません。',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(label, style: theme.textTheme.bodySmall),
    );
  }
}
