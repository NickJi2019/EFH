import 'dart:convert';
import 'dart:io';

import 'host.dart';
import 'processor.dart';
import 'reporter.dart';

/// One Cloudflare Radar "Top N" ranking list.
class Bucket {
  const Bucket(this.top);

  final int top;

  /// The human readable bucket name, e.g. "Top 2,000".
  String get label => 'Top ${formatTop(top)}';

  @override
  bool operator ==(Object other) => other is Bucket && other.top == top;

  @override
  int get hashCode => top.hashCode;

  @override
  String toString() => label;
}

/// The official Cloudflare Radar buckets.
const rankingBuckets = <Bucket>[
  Bucket(200),
  Bucket(500),
  Bucket(1000),
  Bucket(2000),
  Bucket(5000),
  Bucket(10000),
  Bucket(20000),
  Bucket(50000),
  Bucket(100000),
  Bucket(200000),
  Bucket(500000),
  Bucket(1000000),
];

const radarAttachmentUrl =
    'https://radar.cloudflare.com/charts/LargerTopDomainsTable/attachment?top=';
const radarApiStreamUrl =
    'https://api.cloudflare.com/client/v4/radar/datasets/ranking_top_';
const radarUserAgent = 'efh-connectivity/1.0';

/// The default EFHServer base URL, which exposes `GET /top-domains/{top}`.
const efhServerBaseUrl = 'https://vpn.woznes.com';

/// The environment variable holding the optional Radar API token.
const radarTokenEnv = 'CF_Token';

/// Official guide for creating a Cloudflare API token.
const cloudflareTokenUrl =
    'https://developers.cloudflare.com/fundamentals/api/get-started/create-token/';

/// Which backend serves the Cloudflare Radar lists.
enum RadarSource {
  /// The project's own EFHServer (`GET /top-domains/{top}`), which holds the
  /// `CF_Token` and falls back to the Radar API on HTTP 403.
  efhServer,

  /// Cloudflare Radar directly (public attachment URL, then the authenticated
  /// API when the attachment endpoint returns HTTP 403).
  cloudflare,
}

/// Parses a plain-text domain list, one domain per line (the EFHServer
/// `/top-domains/{top}` response format).
Set<String> parseDomainList(String text) {
  final domains = <String>{};
  for (final line in text.split('\n')) {
    final host = normalizeHost(line);
    if (host.isNotEmpty) {
      domains.add(host);
    }
  }
  return domains;
}

/// Returns the bucket with the given Top value, or null when unknown.
Bucket? findBucket(int top) {
  for (final bucket in rankingBuckets) {
    if (bucket.top == top) {
      return bucket;
    }
  }
  return null;
}

/// Formats an integer with thousands separators.
String formatTop(int top) {
  if (top >= 1000000) {
    return '1,000,000';
  }
  if (top >= 1000) {
    final thousands = top ~/ 1000;
    final rest = top % 1000;
    return '$thousands,${rest.toString().padLeft(3, '0')}';
  }
  return '$top';
}

/// Parses a comma separated list of 1-based bucket indices.
///
/// "all" selects every bucket and an empty value selects `fallback`.
List<Bucket> parseBucketSelection(
  String value,
  List<Bucket> buckets,
  Bucket fallback,
) {
  final text = value.trim().toLowerCase();
  if (text.isEmpty) {
    return [fallback];
  }
  if (text == 'all') {
    return List<Bucket>.of(buckets);
  }
  final seen = <int>{};
  final selected = <Bucket>[];
  for (final part in text.split(',')) {
    final index = int.tryParse(part.trim());
    if (index == null || index < 1 || index > buckets.length) {
      throw FormatException('无效编号 "$part"');
    }
    if (seen.add(index)) {
      selected.add(buckets[index - 1]);
    }
  }
  return selected;
}

/// Parses one 1-based bucket index, or returns `fallback` for an empty value.
Bucket parseSingleBucket(String value, List<Bucket> buckets, Bucket fallback) {
  if (value.trim().isEmpty) {
    return fallback;
  }
  final index = int.tryParse(value.trim());
  if (index == null || index < 1 || index > buckets.length) {
    throw FormatException('无效编号 "$value"');
  }
  return buckets[index - 1];
}

/// Returns the configured Radar API token, if any.
String radarToken() => Platform.environment[radarTokenEnv]?.trim() ?? '';

/// Returns an HTTP client suitable for list downloads.
HttpClient defaultRadarClient() =>
    HttpClient()..connectionTimeout = const Duration(seconds: 90);

/// Fetches one bucket's domain set from EFHServer's `GET /top-domains/{top}`.
///
/// The server returns plain text, one domain per line, and holds the
/// Cloudflare `CF_Token` itself. A non-200 response carries a plain-text error
/// body that is surfaced in the thrown [HttpException].
Future<Set<String>> downloadBucketFromServer(
  Bucket bucket, {
  String baseUrl = efhServerBaseUrl,
  HttpClient? client,
  CancelToken? cancelToken,
}) async {
  final http = client ?? defaultRadarClient();
  final base = baseUrl.replaceAll(RegExp(r'/+$'), '');
  final request = await http.getUrl(
    Uri.parse('$base/top-domains/${bucket.top}'),
  );
  request.headers.set('Accept', 'text/plain,*/*;q=0.1');
  request.headers.set('User-Agent', radarUserAgent);
  if (cancelToken?.isCancelled ?? false) {
    request.abort();
  }
  final response = await request.close();
  final body = await response.transform(utf8.decoder).join();
  if (response.statusCode != HttpStatus.ok) {
    final detail = body.trim();
    throw HttpException(
      'EFHServer ${bucket.label}: HTTP ${response.statusCode}'
      '${detail.isEmpty ? '' : '（$detail）'}',
    );
  }
  return parseDomainList(body);
}

/// Fetches one bucket's domain set.
///
/// If the public attachment endpoint returns HTTP 403 (Cloudflare JavaScript
/// Challenge) it falls back to the authenticated Radar dataset stream,
/// requiring a non-empty [token].
Future<Set<String>> downloadBucket(
  Bucket bucket, {
  HttpClient? client,
  String token = '',
  CancelToken? cancelToken,
}) async {
  final http = client ?? defaultRadarClient();
  final request = await http.getUrl(
    Uri.parse('$radarAttachmentUrl${bucket.top}'),
  );
  request.headers.set('Accept', 'text/csv,text/plain;q=0.9,*/*;q=0.1');
  request.headers.set('User-Agent', radarUserAgent);
  if (cancelToken?.isCancelled ?? false) {
    request.abort();
  }
  final response = await request.close();
  if (response.statusCode == HttpStatus.ok) {
    final body = await response.transform(utf8.decoder).join();
    return readDomainCsv(body);
  }
  await response.drain<void>();
  if (response.statusCode != HttpStatus.forbidden) {
    throw HttpException(
      'download ${bucket.label}: HTTP ${response.statusCode}',
    );
  }
  // The public endpoint may serve a JavaScript challenge to non-browser
  // clients. Use the documented authenticated endpoint instead of trying to
  // defeat that protection.
  if (token.isEmpty) {
    throw HttpException(
      'download ${bucket.label}: HTTP 403（Cloudflare JavaScript Challenge）；'
      '请设置 $radarTokenEnv 后重试',
    );
  }
  return _downloadBucketApi(http, bucket, token);
}

Future<Set<String>> _downloadBucketApi(
  HttpClient http,
  Bucket bucket,
  String token,
) async {
  final request = await http.getUrl(
    Uri.parse('$radarApiStreamUrl${bucket.top}'),
  );
  request.headers.set('Authorization', 'Bearer $token');
  request.headers.set('Accept', 'text/csv,text/plain;q=0.9,*/*;q=0.1');
  request.headers.set('User-Agent', radarUserAgent);
  final response = await request.close();
  if (response.statusCode != HttpStatus.ok) {
    await response.drain<void>();
    throw HttpException(
      'Radar API ${bucket.label}: HTTP ${response.statusCode}'
      '（请确认 $radarTokenEnv 具有 Radar 数据集读取权限）',
    );
  }
  final body = await response.transform(utf8.decoder).join();
  return readDomainCsv(body);
}

/// Downloads and merges the selected buckets and additionally fetches the log
/// bucket, reusing already downloaded lists.
///
/// [source] selects EFHServer (`/top-domains/{top}`) or Cloudflare directly.
/// [baseUrl] is only used for [RadarSource.efhServer], and [token] only for
/// [RadarSource.cloudflare].
Future<({Set<String> merged, Set<String> logDomains})> downloadSelected(
  List<Bucket> selected,
  Bucket logBucket, {
  RadarSource source = RadarSource.efhServer,
  String baseUrl = efhServerBaseUrl,
  HttpClient? client,
  String token = '',
  Reporter reporter = const NopReporter(),
  CancelToken? cancelToken,
}) async {
  final http = client ?? defaultRadarClient();
  final cache = <int, Set<String>>{};

  Future<Set<String>> get(Bucket bucket) async {
    final cached = cache[bucket.top];
    if (cached != null) {
      return cached;
    }
    final Set<String> domains;
    if (source == RadarSource.efhServer) {
      reporter.message('从 EFHServer 下载 ${bucket.label}...');
      domains = await downloadBucketFromServer(
        bucket,
        baseUrl: baseUrl,
        client: http,
        cancelToken: cancelToken,
      );
    } else {
      reporter.message('下载 Cloudflare Radar ${bucket.label}...');
      domains = await downloadBucket(
        bucket,
        client: http,
        token: token,
        cancelToken: cancelToken,
      );
    }
    cache[bucket.top] = domains;
    return domains;
  }

  final merged = <String>{};
  for (final bucket in selected) {
    final domains = await get(bucket);
    merged.addAll(domains);
  }
  final logDomains = await get(logBucket);
  return (merged: merged, logDomains: logDomains);
}
