import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.validate in release mode', () {
    test('rejects the placeholder API host', () {
      expect(
        () => AppConfig.validate(
          apiBaseUrl: 'https://api.example.com',
          isRelease: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a malformed URL', () {
      expect(
        () => AppConfig.validate(
          apiBaseUrl: 'not a url',
          isRelease: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('rejects a non-HTTPS URL', () {
      expect(
        () => AppConfig.validate(
          apiBaseUrl: 'http://api.real-service.dev',
          isRelease: true,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('accepts an absolute HTTPS production URL', () {
      expect(
        () => AppConfig.validate(
          apiBaseUrl: 'https://api.real-service.dev',
          isRelease: true,
        ),
        returnsNormally,
      );
    });
  });

  test('debug mode keeps the template defaults runnable', () {
    expect(
      () => AppConfig.validate(
        apiBaseUrl: 'https://api.example.com',
        isRelease: false,
      ),
      returnsNormally,
    );
  });
}
