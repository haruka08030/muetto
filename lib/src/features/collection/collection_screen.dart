import 'package:flutter/material.dart';

import '../log/log_list_screen.dart';
import 'collection_items_view.dart';
import 'wishlist_view.dart';

/// 自分の記録をまとめる場所。
///
/// ログ（S-09）・所持品（S-10）・欲しいもの（S-12）はどれも
/// 「自分が持っている情報」なので、タブを分けずここに並べる。
/// ボトムのタブは 5 つで埋まっており、増やすと押しにくくなる。
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('コレクション'),
          // AppBar の下にタブを置く。中身ごと切り替わる。
          bottom: const TabBar(
            tabs: [
              Tab(text: 'ログ'),
              Tab(text: '所持品'),
              Tab(text: '欲しいもの'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // ログ一覧は自前で AppBar を持つので、ここでは中身だけ使う。
            LogListView(),
            CollectionItemsView(),
            WishlistView(),
          ],
        ),
      ),
    );
  }
}
