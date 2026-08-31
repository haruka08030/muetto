import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// 香水を選んだあとに何をするか。
enum AddAction {
  /// 試したので評価を残す。
  tasted,

  /// 手元にある。
  owned,

  /// 気になっている。
  wanted,
}

/// 香水を選んだあとの行き先を尋ねる。
///
/// 追加の入口を中央 FAB ひとつにまとめてある。香水を先に選ぶのは、
/// どの操作でも対象の香水が要るためで、選ぶ手順を三度書かずに済む。
Future<AddAction?> showAddActionSheet(BuildContext context, String name) {
  return showModalBottomSheet<AddAction>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const _Option(
            action: AddAction.tasted,
            icon: Icons.star_outline,
            title: '試した',
            subtitle: '評価とメモを残す',
          ),
          const _Option(
            action: AddAction.owned,
            icon: Icons.style_outlined,
            title: '持ってる',
            subtitle: 'コレクションに入れる',
          ),
          const _Option(
            action: AddAction.wanted,
            icon: Icons.favorite_outline,
            title: '欲しい',
            subtitle: '気になるものとして残す',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.action,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final AddAction action;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => Navigator.of(context).pop(action),
    );
  }
}
