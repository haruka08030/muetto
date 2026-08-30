import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muetto/src/core/env.dart';
import 'package:muetto/src/features/auth/auth_controller.dart';

void main() {
  group('GuestMode', () {
    test('既定ではゲストではない', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(guestModeProvider), isFalse);
    });

    test('GUEST_MODE が無効なら enter() を呼んでもゲストにならない', () {
      // このテストは --dart-define=GUEST_MODE なしで実行される前提。
      // リリースビルドで導線が無効であることを担保する。
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(guestModeProvider.notifier).enter();

      expect(Env.guestModeEnabled, isFalse);
      expect(container.read(guestModeProvider), isFalse);
    });

    test('exit() でゲスト状態が解除される', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(guestModeProvider.notifier)
        ..enter()
        ..exit();

      expect(container.read(guestModeProvider), isFalse);
    });
  });
}
