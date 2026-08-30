import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';

/// Phase 0 時点のホーム。
/// 検索・ログ・コレクション・分析は Phase 1 以降で実装する。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider).value;
    final isGuest = ref.watch(guestModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: isGuest ? 'ゲスト閲覧をやめる' : 'ログアウト',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isGuest
                  ? 'ゲストとして閲覧中（記録の保存はできません）'
                  : 'ログイン中: ${session?.user.email ?? '-'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              elevation: 0,
              shape: AppShapes.card,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  '香水検索まで実装済みです。\n'
                  '試香ログ・好み分析は Phase 2 以降で追加します。',
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              // 検索はタブなので、ホームの上に積まず検索タブへ移す。
              // push すると下のタブバーの選択と食い違う。
              onPressed: () =>
                  StatefulNavigationShell.of(context).goBranch(Tabs.search),
              icon: const Icon(Icons.search),
              label: const Text('香水を検索する'),
            ),
          ],
        ),
      ),
    );
  }
}
