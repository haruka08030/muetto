import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_draft.dart';

/// 未送信の試香ログを端末に置く。
///
/// 件数は多くても数件で、検索も要らない。ローカル DB を入れるより
/// キーと値の保存で足りる。
class DraftStore {
  const DraftStore();

  static const _key = 'tasting_log_drafts';

  Future<List<LogDraft>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return LogDraft.decodeList(prefs.getString(_key));
  }

  Future<void> add(LogDraft draft) async {
    final drafts = await load();
    await _save([...drafts, draft]);
  }

  Future<void> remove(String draftId) async {
    final drafts = await load();
    await _save(drafts.where((draft) => draft.id != draftId).toList());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<LogDraft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, LogDraft.encodeList(drafts));
  }
}

final draftStoreProvider = Provider<DraftStore>((ref) => const DraftStore());
