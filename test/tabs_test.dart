import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/core/router.dart';

void main() {
  group('Tabs', () {
    test('並び順は StatefulShellRoute の branches と一致している', () {
      // branches の順を変えたらここも変わる。番号がずれると
      // 「検索タブを開いたつもりがログタブ」のような取り違えが起きる。
      expect(Tabs.home, 0);
      expect(Tabs.search, 1);
      expect(Tabs.log, 2);
      expect(Tabs.collection, 3);
      expect(Tabs.analysis, 4);
    });

    test('ログより後ろはアカウントが要るタブとして並べる', () {
      // AppShell はこの並びを前提に、log 以降をゲストに開かせない。
      expect(Tabs.log, lessThan(Tabs.collection));
      expect(Tabs.collection, lessThan(Tabs.analysis));
    });
  });

  group('Routes.perfumeUnder', () {
    test('ホームタブでは先頭のスラッシュが重ならない', () {
      expect(Routes.perfumeUnder(Routes.home, 'abc'), '/perfume/abc');
    });

    test('他のタブではそのタブの下に積む', () {
      expect(Routes.perfumeUnder(Routes.search, 'abc'), '/search/perfume/abc');
      expect(
        Routes.perfumeUnder(Routes.collection, 'abc'),
        '/collection/perfume/abc',
      );
    });
  });
}
