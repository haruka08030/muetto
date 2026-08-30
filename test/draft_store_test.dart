import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/data/draft_store.dart';
import 'package:muetto/src/models/log_draft.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // 端末の保存を模したもの。テストごとに空から始める。
    SharedPreferences.setMockInitialValues({});
  });

  const store = DraftStore();

  LogDraft draft(String id) => LogDraft(
    id: id,
    perfumeId: 'p1',
    perfumeNameEn: 'Yuzu no Asa',
    rating: 4,
    createdAt: DateTime.parse('2026-08-30T10:00:00.000'),
  );

  test('何も無ければ空', () async {
    expect(await store.load(), isEmpty);
  });

  test('足したものが残る', () async {
    await store.add(draft('d1'));
    await store.add(draft('d2'));

    final loaded = await store.load();
    expect(loaded.map((d) => d.id), ['d1', 'd2']);
  });

  test('送れたものだけ消え、残りは残る', () async {
    await store.add(draft('d1'));
    await store.add(draft('d2'));

    await store.remove('d1');

    final loaded = await store.load();
    expect(loaded.map((d) => d.id), ['d2']);
  });

  test('無い ID を消しても壊れない', () async {
    await store.add(draft('d1'));

    await store.remove('存在しない');

    expect((await store.load()).map((d) => d.id), ['d1']);
  });

  test('まとめて消せる', () async {
    await store.add(draft('d1'));
    await store.clear();

    expect(await store.load(), isEmpty);
  });
}
