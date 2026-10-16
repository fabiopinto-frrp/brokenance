import 'package:brokenance/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('development builds may use the local http API', () {
    expect(() => AppConfig.checkSecureUrl('http://localhost:3000', release: false), returnsNormally);
  });

  test('release builds refuse a plain http API', () {
    expect(() => AppConfig.checkSecureUrl('http://api.example.com', release: true), throwsStateError);
    expect(() => AppConfig.checkSecureUrl('https://api.example.com', release: true), returnsNormally);
  });
}
