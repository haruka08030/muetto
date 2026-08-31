import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/core/env.dart';

/// 匿名サインインは開発用の導線で、リリースビルドには出さない。
/// ここではその境目だけを固定する。実際のサインインは Supabase の
/// セッションが要るので、ユニットテストの対象にしない。
void main() {
  group('Env.guestModeEnabled', () {
    test('--dart-define なしでは無効', () {
      // このテストは GUEST_MODE を渡さずに実行される前提。
      // リリースビルドで匿名の導線が出ないことを担保する。
      expect(Env.guestModeEnabled, isFalse);
    });
  });
}
