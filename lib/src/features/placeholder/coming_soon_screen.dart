import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// まだ実装していないタブの中身。
///
/// タブ自体は先に置く（docs/screens.md 2）。アプリの骨格を早く固定するため、
/// 未実装でもタブを隠さず、ここで「いつ作るか」を伝える。
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    required this.title,
    required this.phase,
    required this.description,
    required this.icon,
    this.showAppBar = true,
    super.key,
  });

  final String title;

  /// 実装予定のフェーズ番号（docs/roadmap.md）。
  final int phase;

  /// この画面で何ができるようになるか。
  final String description;

  final IconData icon;

  /// 内タブの中で使うときは、外側が AppBar を持つので出さない。
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.lg),
              Text(
                description,
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Phase $phase で作ります',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
