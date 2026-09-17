import 'package:efh_connectivity_test/connectivity/update_checker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('version comparison ignores v prefix, build metadata and prerelease', () {
    expect(isNewerVersion('v1.0.1', '1.0.0'), isTrue);
    expect(isNewerVersion('v1.0.0', '1.0.0'), isFalse);
    expect(isNewerVersion('1.0', '1.0.0'), isFalse);
    expect(isNewerVersion('v1.1.0', '1.0.9'), isTrue);
    expect(isNewerVersion('v1.0.0+5', '1.0.0'), isFalse);
    expect(isNewerVersion('v2.0.0-rc1', '1.9.9'), isTrue);
  });

  test('numeric parts compare numerically, not lexically', () {
    expect(compareVersions('1.2.10', '1.2.3'), greaterThan(0));
    expect(compareVersions('1.10', '1.9'), greaterThan(0));
  });
}
