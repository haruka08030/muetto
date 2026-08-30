import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/collection_repository.dart';
import '../../models/collection.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';
import 'collection_controller.dart';

/// 香水詳細に置く「持っている」「欲しい」。
///
/// ここが唯一のコレクション追加の入口になる。一覧側に追加ボタンを置くと、
/// そこから香水を選び直すことになり、香水詳細を見ている流れが切れる。
class AddToCollectionActions extends ConsumerWidget {
  const AddToCollectionActions({required this.perfumeId, super.key});

  final String perfumeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ゲストは RLS で弾かれる。押せるのに保存されない状態を作らない。
    if (ref.watch(guestModeProvider)) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addToCollection(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('持っている'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _addToWishlist(context, ref),
            icon: const Icon(Icons.favorite_outline),
            label: const Text('欲しい'),
          ),
        ),
      ],
    );
  }

  Future<void> _addToCollection(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_CollectionInput>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CollectionSheet(),
    );
    if (result == null) {
      return;
    }

    try {
      await ref
          .read(collectionRepositoryProvider)
          .addItem(
            perfumeId: perfumeId,
            acquisitionType: result.type,
            volumeMl: result.volumeMl,
          );
      ref.invalidate(collectionItemsProvider);
      if (context.mounted) {
        _toast(context, 'コレクションに追加しました');
      }
    } catch (error) {
      if (context.mounted) {
        _toast(context, '追加できませんでした: $error');
      }
    }
  }

  Future<void> _addToWishlist(BuildContext context, WidgetRef ref) async {
    final priority = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => const _PrioritySheet(),
    );
    if (priority == null) {
      return;
    }

    try {
      await ref
          .read(collectionRepositoryProvider)
          .addToWishlist(perfumeId: perfumeId, priority: priority);
      ref.invalidate(wishlistProvider);
      if (context.mounted) {
        _toast(context, '欲しいものに追加しました');
      }
    } catch (error) {
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

class _CollectionInput {
  const _CollectionInput({required this.type, this.volumeMl});

  final AcquisitionType type;
  final double? volumeMl;
}

class _CollectionSheet extends StatefulWidget {
  const _CollectionSheet();

  @override
  State<_CollectionSheet> createState() => _CollectionSheetState();
}

class _CollectionSheetState extends State<_CollectionSheet> {
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
                _CollectionInput(
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

class _PrioritySheet extends StatelessWidget {
  const _PrioritySheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
    );
  }
}
