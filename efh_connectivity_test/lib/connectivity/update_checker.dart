import 'dart:convert';
import 'dart:io';

import 'app_version.dart';

/// A published GitHub release of the client.
class ReleaseInfo {
  const ReleaseInfo({
    required this.tag,
    required this.name,
    required this.url,
    this.publishedAt,
  });

  /// The release tag, e.g. `v1.2.0`.
  final String tag;

  /// The human-readable release name (falls back to [tag]).
  final String name;

  /// The GitHub release page.
  final String url;

  final DateTime? publishedAt;
}

/// Checks GitHub for a newer client release.
///
/// Uses `releases/latest`, which GitHub defines as the most recent
/// **non-prerelease, non-draft** release. Prereleases are reserved for the
/// server, so they are deliberately ignored.
class UpdateChecker {
  UpdateChecker({this.timeout = const Duration(seconds: 10)});

  final Duration timeout;

  static final Uri _latestRelease = Uri.parse(
    'https://api.github.com/repos/NickJi2019/EFH/releases/latest',
  );

  /// The latest public release, or null when it cannot be determined.
  Future<ReleaseInfo?> fetchLatest() async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(_latestRelease);
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'efh-connectivity-test/$appVersion',
      );
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return null;
      }
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return null;
      }
      final tag = decoded['tag_name'];
      if (tag is! String || tag.trim().isEmpty) {
        return null;
      }
      final name = decoded['name'];
      final url = decoded['html_url'];
      final published = decoded['published_at'];
      return ReleaseInfo(
        tag: tag.trim(),
        name: (name is String && name.trim().isNotEmpty)
            ? name.trim()
            : tag.trim(),
        url: url is String && url.isNotEmpty
            ? url
            : 'https://github.com/NickJi2019/EFH/releases',
        publishedAt: published is String ? DateTime.tryParse(published) : null,
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

/// Compares two dotted version strings, ignoring a leading `v`, any build
/// metadata (`+n`) and any prerelease suffix (`-rc1`).
///
/// Returns a positive number when [a] is newer than [b].
int compareVersions(String a, String b) {
  final left = _parts(a);
  final right = _parts(b);
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) {
      return l - r;
    }
  }
  return 0;
}

/// Whether [latest] is a newer version than [current].
bool isNewerVersion(String latest, String current) =>
    compareVersions(latest, current) > 0;

List<int> _parts(String version) {
  var text = version.trim();
  if (text.startsWith('v') || text.startsWith('V')) {
    text = text.substring(1);
  }
  text = text.split('+').first.split('-').first;
  return [
    for (final part in text.split('.'))
      int.tryParse(part.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
  ];
}
