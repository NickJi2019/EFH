import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

/// Fetches site favicons with an in-memory cache and a strict concurrency
/// limit.
///
/// Flutter's [Image.network] would open one connection per visible row, so a
/// screenful of results triggers dozens of simultaneous DNS lookups and TLS
/// handshakes. Limiting the fan-out keeps page switches and scrolling smooth.
class FaviconCache {
  FaviconCache({
    this.maxConcurrent = 4,
    this.timeout = const Duration(seconds: 6),
  });

  final int maxConcurrent;
  final Duration timeout;

  static const int _maxBytes = 256 * 1024;

  final Map<String, Uint8List?> _cache = {};
  final Map<String, Future<Uint8List?>> _pending = {};
  final List<Completer<void>> _waiters = [];
  int _active = 0;

  /// Whether [host] has already been resolved (a failure counts as resolved).
  bool isCached(String host) => _cache.containsKey(host);

  /// The cached bytes for [host], or null when unknown/failed/not cached.
  Uint8List? cached(String host) => _cache[host];

  /// Returns the favicon bytes, or null when unavailable. Cached per host.
  Future<Uint8List?> get(String host) {
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

  Future<Uint8List?> _fetch(String host) async {
    await _acquire();
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(
        Uri.parse('https://$host/favicon.ico'),
      );
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (compatible; efh-connectivity/1.0)',
      );
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        return _store(host, null);
      }
      final builder = BytesBuilder(copy: false);
      var size = 0;
      // A stalled body must not hold the concurrency slot forever.
      await for (final chunk in response.timeout(timeout)) {
        size += chunk.length;
        if (size > _maxBytes) {
          break;
        }
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      return _store(host, bytes.isEmpty ? null : bytes);
    } catch (_) {
      return _store(host, null);
    } finally {
      client.close(force: true);
      _release();
    }
  }

  Uint8List? _store(String host, Uint8List? bytes) {
    _cache[host] = bytes;
    _pending.remove(host);
    return bytes;
  }
}
