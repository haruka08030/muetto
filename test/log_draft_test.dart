import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/models/log_draft.dart';

void main() {
  group('LogDraft', () {
    test('書き出して読み戻すと同じ内容になる', () {
      final draft = LogDraft(
        id: 'd1',
        perfumeId: 'p1',
        perfumeNameEn: 'Yuzu no Asa',
        perfumeNameJa: '柚子の朝',
        brandNameEn: 'Maison Hikari',
        brandNameJa: 'メゾン・ヒカリ',
        rating: 4.2,
        memo: '朝つけたい',
        method: 'skin',
        wantToBuy: true,
        createdAt: DateTime.parse('2026-08-30T10:00:00.000'),
      );

      final restored = LogDraft.decodeList(LogDraft.encodeList([draft])).single;

      expect(restored.id, draft.id);
      expect(restored.rating, draft.rating);
      expect(restored.memo, draft.memo);
      expect(restored.method, draft.method);
      expect(restored.wantToBuy, isTrue);
      expect(restored.createdAt, draft.createdAt);
      // 香水名を持っているので、電波が無くても一覧に出せる。
      expect(restored.perfumeNameJa, '柚子の朝');
      expect(restored.brandNameJa, 'メゾン・ヒカリ');
    });

    test('任意の項目が無くても読める', () {
      final draft = LogDraft(
        id: 'd1',
        perfumeId: 'p1',
        perfumeNameEn: 'Kohaku',
        rating: 3,
        createdAt: DateTime.parse('2026-08-30T10:00:00.000'),
      );

      final restored = LogDraft.decodeList(LogDraft.encodeList([draft])).single;

      expect(restored.memo, isNull);
      expect(restored.method, isNull);
      expect(restored.perfumeNameJa, isNull);
      expect(restored.wantToBuy, isFalse);
    });

    test('保存が空でも壊れていても、起動を止めずに空で返す', () {
      // ここで例外を投げるとアプリ全体が使えなくなる。
      expect(LogDraft.decodeList(null), isEmpty);
      expect(LogDraft.decodeList(''), isEmpty);
      expect(LogDraft.decodeList('壊れた文字列'), isEmpty);
      expect(LogDraft.decodeList('{"not":"a list"}'), isEmpty);
    });

    test('複数件を順番どおりに保つ', () {
      final drafts = [
        for (var i = 0; i < 3; i++)
          LogDraft(
            id: 'd$i',
            perfumeId: 'p$i',
            perfumeNameEn: 'P$i',
            rating: 3,
            createdAt: DateTime.parse('2026-08-3${i}T10:00:00.000'),
          ),
      ];

      final restored = LogDraft.decodeList(LogDraft.encodeList(drafts));

      expect(restored.map((d) => d.id), ['d0', 'd1', 'd2']);
    });
  });
}
