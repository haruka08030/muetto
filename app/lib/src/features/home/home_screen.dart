import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../auth/auth_controller.dart';

/// Phase 0 時点のホーム。
/// 検索・ログ・コレクション・分析は Phase 1 以降で実装する。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
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
              'ログイン中: ${session?.user.email ?? '-'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              elevation: 0,
              shape: AppShapes.card,
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Phase 0（基盤）まで実装済みです。\n'
                  '香水検索・試香ログ・好み分析は Phase 1 以降で追加します。',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
