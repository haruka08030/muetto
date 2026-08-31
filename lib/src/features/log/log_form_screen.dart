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
  const LogFormScreen({required this.perfume, this.existing, super.key});

  final PerfumeSummary perfume;

  /// 渡すと書き換えになる。null なら新規。
  final TastingLog? existing;

  @override
  ConsumerState<LogFormScreen> createState() => _LogFormScreenState();
}

class _LogFormScreenState extends ConsumerState<LogFormScreen> {
  late final TextEditingController _memo;
  late double _rating;
  late bool _wantToBuy;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _memo = TextEditingController(text: existing?.memo ?? '');
    _rating = existing?.rating ?? 0;
    _wantToBuy = existing?.wantToBuy ?? false;
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  bool get _canSave => _rating > 0;

  Future<void> _save() async {
    final controller = ref.read(logControllerProvider.notifier);
    final existing = widget.existing;

    // 書き換えは下書きに落とさない。元がサーバにあるので、
    // 端末側に別の版を作ると、どちらが正しいか決められなくなる。
    if (existing != null) {
      final updated = await controller.update(
        logId: existing.id,
        perfumeId: widget.perfume.id,
        rating: _rating,
        memo: _memo.text,
        wantToBuy: _wantToBuy,
      );
      if (updated && mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    final result = await controller.save(
      perfume: widget.perfume,
      rating: _rating,
      memo: _memo.text,
      wantToBuy: _wantToBuy,
    );

    if (!mounted || result == LogSaveResult.failed) {
      return;
    }

    // 下書きになったことは伝えるが、失敗としては見せない。
    // オフラインであることを意識させない（docs/screens.md 3）。
    if (result == LogSaveResult.draft) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('通信できないため端末に保存しました。あとで自動的に送ります')),
        );
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
        title: Text(_isEditing ? 'ログを編集' : '試香ログ'),
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
        ],
      ),
      // 保存は常に押せる場所に置く。一覧の中に入れると、
      // 内容が伸びたときに画面外へ出てスクロールが要る。
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: FilledButton(
            onPressed: (!_canSave || state.isLoading) ? null : _save,
            child: state.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? '更新する' : '保存する'),
          ),
        ),
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
