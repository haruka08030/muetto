import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/localized.dart';
import '../../models/perfume.dart';
import '../../models/tasting_log.dart';
import '../../theme/app_theme.dart';
import 'log_controller.dart';
import 'rating_stars.dart';

/// 試香ログの入力（S-08）。
///
/// 店頭で使うので、星をタップした時点で保存できる状態にする。
/// メモも方法も必須にしない（docs/screens.md 3）。
class LogFormScreen extends ConsumerStatefulWidget {
  const LogFormScreen({required this.perfume, super.key});

  final PerfumeSummary perfume;

  @override
  ConsumerState<LogFormScreen> createState() => _LogFormScreenState();
}

class _LogFormScreenState extends ConsumerState<LogFormScreen> {
  final _memo = TextEditingController();
  double _rating = 0;
  TastingMethod? _method;
  bool _wantToBuy = false;

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  bool get _canSave => _rating > 0;

  Future<void> _save() async {
    final saved = await ref
        .read(logControllerProvider.notifier)
        .save(
          perfumeId: widget.perfume.id,
          rating: _rating,
          memo: _memo.text,
          method: _method?.value,
          wantToBuy: _wantToBuy,
        );

    if (!saved || !mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logControllerProvider);
    ref.listen(logControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('保存できませんでした: $error')));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('試香ログ'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _PerfumeHeader(perfume: widget.perfume),
          const SizedBox(height: AppSpacing.xl),

          // 最初に評価。ここだけで保存できる。
          Center(
            child: Column(
              children: [
                RatingStars(
                  rating: _rating,
                  onChanged: (value) => setState(() => _rating = value),
                ),
                const SizedBox(height: AppSpacing.sm),
                RatingValue(rating: _rating),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text('どう試したか', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final method in TastingMethod.values)
                ChoiceChip(
                  label: Text(method.label),
                  selected: _method == method,
                  onSelected: (selected) =>
                      setState(() => _method = selected ? method : null),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _memo,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'メモ（任意）',
              hintText: '香りの印象、そのときの状況など',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          SwitchListTile(
            value: _wantToBuy,
            onChanged: (value) => setState(() => _wantToBuy = value),
            title: const Text('買いたい'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.lg),

          FilledButton(
            onPressed: (!_canSave || state.isLoading) ? null : _save,
            child: state.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存する'),
          ),
        ],
      ),
    );
  }
}

class _PerfumeHeader extends StatelessWidget {
  const _PerfumeHeader({required this.perfume});

  final PerfumeSummary perfume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizedName(
            nameEn: perfume.brandNameEn,
            nameJa: perfume.brandNameJa,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          localizedName(nameEn: perfume.nameEn, nameJa: perfume.nameJa),
          style: theme.textTheme.titleLarge,
        ),
      ],
    );
  }
}
