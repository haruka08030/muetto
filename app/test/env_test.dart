import 'package:flutter_test/flutter_test.dart';
import 'package:perfume_app/src/core/env.dart';

void main() {
  group('Env', () {
    test('両方揃っていれば有効', () {
      const env = Env(
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'publishable-key',
      );
      expect(env.isValid, isTrue);
    });

    test('欠けている項目名がメッセージに出る', () {
      const env = Env(supabaseUrl: '', supabasePublishableKey: '');
      expect(env.isValid, isFalse);
      expect(env.validationMessage, contains('SUPABASE_URL'));
      expect(env.validationMessage, contains('SUPABASE_PUBLISHABLE_KEY'));
    });

    test('片方だけ欠けている場合はその項目だけ出る', () {
      const env = Env(
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: '',
      );
      expect(env.isValid, isFalse);
      expect(env.validationMessage, contains('SUPABASE_PUBLISHABLE_KEY'));
      expect(env.validationMessage, isNot(contains('SUPABASE_URL')));
    });
  });
}
