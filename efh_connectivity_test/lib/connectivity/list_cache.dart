import 'dart:io';

import 'processor.dart';
import 'radar.dart';

/// Caches Cloudflare Radar Top-N domain lists on disk and refreshes them when
/// they are older than [freshness] (7 days).
///
/// Lists are stored one domain per line at
/// `<home>/.efh_connectivity_test/cache/top-<n>.txt`.
class ListCache {
  ListCache({Directory? directory})
    : directory = directory ?? Directory(_defaultPath());

  final Directory directory;

  /// How long a cached list is considered up to date.
  static const Duration freshness = Duration(days: 7);

  static String _defaultPath() {
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    return '$home/.efh_connectivity_test/cache';
  }

  File fileFor(int top) => File('${directory.path}/top-$top.txt');

  /// Whether a cached list exists and is younger than [freshness].
  bool isFreshSync(int top) {
    final file = fileFor(top);
    if (!file.existsSync()) {
      return false;
    }
    return DateTime.now().difference(file.statSync().modified) < freshness;
  }

  DateTime? lastUpdatedSync(int top) {
    final file = fileFor(top);
    if (!file.existsSync()) {
      return null;
    }
    return file.statSync().modified;
  }

  /// Reads a cached list, or null when it is missing or unreadable.
  Future<Set<String>?> read(int top) async {
    final file = fileFor(top);
    if (!file.existsSync()) {
      return null;
    }
    try {
      return parseDomainList(await file.readAsString());
    } catch (_) {
      return null;
    }
  }

  /// Writes a list to disk (sorted, one domain per line).
  Future<Set<String>> write(int top, Set<String> domains) async {
    await directory.create(recursive: true);
    final sorted = domains.toList()..sort();
    await fileFor(top).writeAsString(sorted.join('\n'));
    return domains;
  }

  /// Downloads and caches a list, regardless of its age.
  Future<Set<String>> refresh(
    Bucket bucket, {
    RadarSource source = RadarSource.efhServer,
    String baseUrl = efhServerBaseUrl,
    String token = '',
    HttpClient? client,
    CancelToken? cancelToken,
  }) async {
    final domains = source == RadarSource.efhServer
        ? await downloadBucketFromServer(
            bucket,
            baseUrl: baseUrl,
            client: client,
            cancelToken: cancelToken,
          )
        : await downloadBucket(
            bucket,
            client: client,
            token: token,
            cancelToken: cancelToken,
          );
    return write(bucket.top, domains);
  }

  /// Returns a fresh cached list, downloading it when missing or stale.
  Future<Set<String>> load(
    Bucket bucket, {
    RadarSource source = RadarSource.efhServer,
    String baseUrl = efhServerBaseUrl,
    String token = '',
    HttpClient? client,
    CancelToken? cancelToken,
    bool force = false,
  }) async {
    if (!force && isFreshSync(bucket.top)) {
      final cached = await read(bucket.top);
      if (cached != null) {
        return cached;
      }
    }
    return refresh(
      bucket,
      source: source,
      baseUrl: baseUrl,
      token: token,
      client: client,
      cancelToken: cancelToken,
    );
  }
}
