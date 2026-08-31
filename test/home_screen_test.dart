import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/features/home/home_screen.dart';
import 'package:muetto/src/features/auth/auth_controller.dart';
import 'package:muetto/src/features/log/draft_sync.dart';
import 'package:muetto/src/features/log/log_list_controller.dart';
import 'package:muetto/src/models/tasting_log.dart';

/// ホームは最近の記録を出す。認証まわりは Supabase を初期化しないと
/// 触れないので、テストでは差し替えて表示だけを見る。
void main() {
  Future<void> pumpHome(
    WidgetTester tester, {
    required List<TastingLogWithPerfume> logs,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentLogsProvider.overrideWith((ref) async => logs),
          // ホームは認証状態と下書きを見る。どちらも Supabase に触るので、
          // テストではその手前で差し替える。
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          draftsProvider.overrideWith((ref) async => []),
          draftSyncProvider.overrideWith(() => _NoSync()),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('記録が無ければ書き方を案内する', (tester) async {
    await pumpHome(tester, logs: const []);

    expect(find.textContaining('まだ記録がありません'), findsOneWidget);
    // 空のときに「すべて見る」を出しても行き先が空。
    expect(find.text('すべて見る'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('記録があれば香水名と評価を出す', (tester) async {
    await pumpHome(tester, logs: [_item()]);

    expect(find.text('柚子の朝'), findsOneWidget);
    expect(find.text('メゾン・ヒカリ'), findsOneWidget);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('すべて見る'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

TastingLogWithPerfume _item() => TastingLogWithPerfume.fromJson({
  'id': 'l1',
  'perfume_id': 'p1',
  'rating': 4.2,
  'tested_at': '2026-08-30',
  'perfumes': {
    'id': 'p1',
    'name_en': 'Yuzu no Asa',
    'name_ja': '柚子の朝',
    'concentration': 'edt',
    'is_verified': true,
    'brands': {'name_en': 'Maison Hikari', 'name_ja': 'メゾン・ヒカリ'},
  },
});

/// 同期を止めるための差し替え。テストでは送信も再取得もしない。
class _NoSync extends DraftSync {
  @override
  Future<int> flush() async => 0;
}
