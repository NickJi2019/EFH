import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'checker.dart';

/// How hostnames are resolved before a TLS probe.
enum DnsMode {
  /// The operating system's resolver (getaddrinfo).
  system,

  /// Cloudflare's DNS-over-HTTPS endpoint.
  cloudflare,

  /// A user-provided DoH endpoint speaking the JSON API.
  custom,
}

/// The Cloudflare DoH endpoint used when [DnsMode.cloudflare] is selected.
const String cloudflareDohUrl = 'https://cloudflare-dns.com/dns-query';

/// Resolves hostnames over DNS-over-HTTPS.
///
/// Uses the JSON API (`?name=&type=`) supported by Cloudflare, Google and
/// several other providers, and caches answers (including failures) per host.
class DohResolver implements HostResolver {
  DohResolver({required this.url, this.timeout = const Duration(seconds: 5)});

  final String url;
  final Duration timeout;

  final Map<String, List<String>> _cache = {};
  final Map<String, Future<List<String>>> _pending = {};

  /// Resolves [host] to its IPv4 (preferred) or IPv6 addresses.
  @override
  Future<List<String>> resolve(String host) {
    final cached = _cache[host];
    if (cached != null) {
      return Future.value(cached);
    }
    return _pending.putIfAbsent(host, () => _query(host));
  }

  Future<List<String>> _query(String host) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      for (final type in const ['A', 'AAAA']) {
        final addresses = await _lookup(client, host, type);
        if (addresses.isNotEmpty) {
          return _store(host, addresses);
        }
      }
      return _store(host, const []);
    } catch (_) {
      return _store(host, const []);
    } finally {
      client.close(force: true);
      _pending.remove(host);
    }
  }

  Future<List<String>> _lookup(
    HttpClient client,
    String host,
    String type,
  ) async {
    final base = Uri.parse(url);
    final uri = base.replace(
      queryParameters: {...base.queryParameters, 'name': host, 'type': type},
    );
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/dns-json');
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return const [];
    }
    final body = await response.transform(utf8.decoder).join().timeout(timeout);
    return parseDohAnswers(
      jsonDecode(body),
      type == 'AAAA' ? dohTypeAaaa : dohTypeA,
    );
  }

  List<String> _store(String host, List<String> addresses) {
    _cache[host] = addresses;
    return addresses;
  }
}

/// DNS record types used by the DoH JSON API.
const int dohTypeA = 1;
const int dohTypeAaaa = 28;

/// Extracts the record `data` of type [recordType] from a decoded DoH JSON
/// response. Kept separate from the network code so it can be unit tested.
List<String> parseDohAnswers(Object? decoded, int recordType) {
  if (decoded is! Map) {
    return const [];
  }
  final answers = decoded['Answer'];
  if (answers is! List) {
    return const [];
  }
  return [
    for (final answer in answers)
      if (answer is Map &&
          answer['type'] == recordType &&
          answer['data'] is String)
        answer['data'] as String,
  ];
}
