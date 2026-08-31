import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_repository.dart';
import '../../models/collection.dart';
import '../../models/perfume.dart';
import '../../theme/app_theme.dart';
import '../log/log_form_screen.dart';
import 'collection_controller.dart';

/// 香水詳細に置く三つの操作。
///
/// 追加はすべてこの画面から始まる。香水を特定してから何をするか決める
/// ほうが、操作を選んでから香水を探すより迷いが少ない（Vivino も
/// 製品ページを中心に据えている。docs/screens.md 6）。
///
/// 三つは意味が違うので見た目で区別する。試したのは事実の記録、
/// 持ってるのは所有、欲しいのは願望で、取り消しやすさも違う。
class AddToCollectionActions extends ConsumerWidget {
  const AddToCollectionActions({required this.perfume, super.key});

  final PerfumeSummary perfume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // 試したは記録が主目的なので、いちばん押されるものとして強調する。
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _openLogForm(context),
            icon: const Icon(Icons.star_outline, size: 20),
            label: const Text('試した'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addToCollection(context, ref),
            icon: const Icon(Icons.style_outlined, size: 20),
            label: const Text('持ってる'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addToWishlist(context, ref),
            icon: const Icon(Icons.favorite_outline, size: 20),
            label: const Text('欲しい'),
          ),
        ),
      ],
    );
  }

  Future<void> _openLogForm(BuildContext context) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => LogFormScreen(perfume: perfume),
      ),
    );
  }

  Future<void> _addToCollection(BuildContext context, WidgetRef ref) async {
    final input = await showModalBottomSheet<CollectionInput>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CollectionSheet(),
    );
    if (input == null) {
      return;
    }

    try {
      await ref
          .read(collectionRepositoryProvider)
          .addItem(
            perfumeId: perfume.id,
            acquisitionType: input.type,
            volumeMl: input.volumeMl,
          );
      ref.invalidate(collectionItemsProvider);
      if (context.mounted) {
        _toast(context, 'コレクションに追加しました');
      }
    } on Object catch (error) {
      if (context.mounted) {
        _toast(context, '追加できませんでした: $error');
      }
    }
  }

  Future<void> _addToWishlist(BuildContext context, WidgetRef ref) async {
    final priority = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => const PrioritySheet(),
    );
    if (priority == null) {
      return;
    }

    try {
      await ref
          .read(collectionRepositoryProvider)
          .addToWishlist(perfumeId: perfume.id, priority: priority);
      ref.invalidate(wishlistProvider);
      if (context.mounted) {
        _toast(context, '欲しいものに追加しました');
      }
    } on Object catch (error) {
      if (context.mounted) {
        _toast(context, '追加できませんでした: $error');
      }
    }
  }

  static void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// 所持品を追加するときの入力。
class CollectionInput {
  const CollectionInput({required this.type, this.volumeMl});

  final AcquisitionType type;
  final double? volumeMl;
}

class CollectionSheet extends StatefulWidget {
  const CollectionSheet({super.key});

  @override
  State<CollectionSheet> createState() => _CollectionSheetState();
}

class _CollectionSheetState extends State<CollectionSheet> {
  AcquisitionType _type = AcquisitionType.fullBottle;
  final _volume = TextEditingController();

  @override
  void dispose() {
    _volume.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          // キーボードで隠れないよう持ち上げる。
          bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('コレクションに追加', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            Text('手に入れ方', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final type in AcquisitionType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    selected: _type == type,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _volume,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '容量（任意）',
                suffixText: 'ml',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(
                CollectionInput(
                  type: _type,
                  volumeMl: double.tryParse(_volume.text.trim()),
                ),
              ),
              child: const Text('追加する'),
            ),
          ],
        ),
      ),
    );
  }
}

class PrioritySheet extends StatelessWidget {
  const PrioritySheet({super.key});

  @override
  Widget build(BuildContext context) {
    // 選択肢が五つあり、画面が低いと収まらない。中身を巻き取る。
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'どれくらい欲しい？',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final entry in const [
              (5, 'とても欲しい'),
              (4, 'かなり欲しい'),
              (3, '気になる'),
              (2, '少し気になる'),
              (1, 'いつか'),
            ])
              ListTile(
                title: Text(entry.$2),
                onTap: () => Navigator.of(context).pop(entry.$1),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}
