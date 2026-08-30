import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';

/// タブの外枠。ボトムナビゲーションと中央 FAB を持つ。
///
/// タブの中身は [StatefulShellRoute] が差し替える。各タブはそれぞれ
/// ナビゲーション履歴を保つので、検索で香水詳細まで潜ってから他のタブへ
/// 移り、戻ってきても詳細画面のままになる（docs/screens.md 2）。
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// 中央 FAB の分だけ、ナビゲーションの項目を左右に分ける。
  static const _leftTabs = [
    _TabItem(icon: Icons.home_outlined, selected: Icons.home, label: 'ホーム'),
    _TabItem(icon: Icons.search_outlined, selected: Icons.search, label: '検索'),
  ];
  static const _rightTabs = [
    _TabItem(
      icon: Icons.style_outlined,
      selected: Icons.style,
      label: 'コレクション',
    ),
    _TabItem(
      icon: Icons.insights_outlined,
      selected: Icons.insights,
      label: '分析',
    ),
  ];



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: _LogButton(
        onPressed: () => _openTab(context, ref, Tabs.log),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _openTab(context, ref, index),
      ),
    );
  }

  /// タブを開く。ゲストのときは記録が要るタブを開かせない。
  void _openTab(BuildContext context, WidgetRef ref, int index) {
    if (_needsAccount(index) && ref.read(guestModeProvider)) {
      _promptSignIn(context, ref);
      return;
    }

    // 同じタブをもう一度押したら、そのタブのルートまで戻す。
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  /// ログインが要るタブか。
  ///
  /// ログ・コレクション・分析はいずれもユーザー自身のデータを読み書きする。
  /// ゲストは RLS で弾かれるので、押しても何も起きない状態を作らない。
  static bool _needsAccount(int index) => index >= Tabs.log;

  void _promptSignIn(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('この機能を使うにはログインが必要です'),
          action: SnackBarAction(
            label: 'ログイン',
            onPressed: () => ref.read(guestModeProvider.notifier).exit(),
          ),
        ),
      );
  }
}

/// 記録の入口。最頻出の操作（店頭での試香記録）なので最短距離に置く。
class _LogButton extends StatelessWidget {
  const _LogButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'ログを書く',
      shape: const CircleBorder(),
      child: const Icon(Icons.add),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: AppSpacing.sm,
      // アイコンとラベルを縦に積むので、既定の 56 では足りない。
      height: 64,
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          for (var i = 0; i < AppShell._leftTabs.length; i++)
            _BarButton(
              item: AppShell._leftTabs[i],
              isSelected: currentIndex == i,
              onTap: () => onTap(i),
            ),
          // 中央 FAB のための空き。
          const SizedBox(width: 56),
          for (var i = 0; i < AppShell._rightTabs.length; i++)
            _BarButton(
              item: AppShell._rightTabs[i],
              // 右側は FAB のぶん 1 つずれる。
              isSelected: currentIndex == i + Tabs.collection,
              onTap: () => onTap(i + Tabs.collection),
            ),
        ],
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _TabItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isSelected ? scheme.primary : scheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? item.selected : item.icon, color: color, size: 24),
              const SizedBox(height: 2),
              // アイコンだけで並べない（docs/screens.md 6）。
              Text(
                item.label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.icon,
    required this.selected,
    required this.label,
  });

  final IconData icon;
  final IconData selected;
  final String label;
}
