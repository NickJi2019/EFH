import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Lazily fetches the HTML `<title>` of a site with an in-memory cache and a
/// small concurrency limit, so a long result list stays responsive.
class SiteMetadata {
  SiteMetadata({
    this.maxConcurrent = 3,
    this.timeout = const Duration(seconds: 5),
  });

  final int maxConcurrent;
  final Duration timeout;

  final Map<String, String?> _cache = {};
  final Map<String, Future<String?>> _pending = {};
  final List<Completer<void>> _waiters = [];
  int _active = 0;

  static final RegExp _titlePattern = RegExp(
    r'<title[^>]*>([\s\S]*?)</title>',
    caseSensitive: false,
  );

  /// Whether [host] has already been resolved (a null title counts as resolved).
  bool isCached(String host) => _cache.containsKey(host);

  /// The cached title for [host], or null when not cached yet.
  String? cachedTitle(String host) => _cache[host];

  /// Returns the page title, or null when unavailable. Cached per host.
  Future<String?> title(String host) {
    if (_cache.containsKey(host)) {
      return Future.value(_cache[host]);
    }
    return _pending.putIfAbsent(host, () => _fetch(host));
  }

  Future<void> _acquire() {
    if (_active < maxConcurrent) {
      _active++;
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    return completer.future;
  }

  void _release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _active--;
    }
  }

  Future<String?> _fetch(String host) async {
    await _acquire();
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(Uri.parse('https://$host'));
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (compatible; efh-connectivity/1.0)',
      );
      request.headers.set(HttpHeaders.acceptHeader, 'text/html,*/*;q=0.1');
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return _store(host, null);
      }
      final bytes = <int>[];
      // A server that connects but never finishes the body would otherwise
      // block this slot forever and starve every other host.
      await for (final chunk in response.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length > 64 * 1024) {
          break;
        }
      }
      final html = utf8.decode(bytes, allowMalformed: true);
      final match = _titlePattern.firstMatch(html);
      final raw = match?.group(1)?.trim();
      final title = (raw == null || raw.isEmpty) ? null : _decodeEntities(raw);
      return _store(host, title);
    } catch (_) {
      return _store(host, null);
    } finally {
      client.close(force: true);
      _release();
    }
  }

  String? _store(String host, String? title) {
    _cache[host] = title;
    _pending.remove(host);
    return title;
  }

  String _decodeEntities(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (match) => String.fromCharCode(int.parse(match.group(1)!)),
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
