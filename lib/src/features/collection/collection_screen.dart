import 'package:flutter/material.dart';

import '../log/log_list_screen.dart';
import '../placeholder/coming_soon_screen.dart';

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
            ComingSoonScreen(
              title: '所持品',
              phase: 2,
              description: '持っている香水と残量を管理できるようにします。',
              icon: Icons.style_outlined,
              showAppBar: false,
            ),
            ComingSoonScreen(
              title: '欲しいもの',
              phase: 2,
              description: '気になる香水を優先度付きで残せるようにします。',
              icon: Icons.favorite_outline,
              showAppBar: false,
            ),
          ],
        ),
      ),
    );
  }
}
