import 'dart:async';
import 'dart:io';

import 'result.dart';
import 'status.dart';

/// The TLS port used when none is given.
const defaultPort = '443';

/// The default number of concurrent probes.
const defaultWorkers = 65536;

/// The default per-host timeout.
const defaultTimeout = Duration(seconds: 8);

/// Resolves a hostname to a list of IP addresses.
///
/// Implemented by the DoH resolver; when a probe has no resolver it falls back
/// to the operating system's resolver.
abstract class HostResolver {
  Future<List<String>> resolve(String host);
}

/// Dials `host:port` and inspects the leaf certificate.
///
/// The handshake deliberately permits an untrusted certificate
/// (`onBadCertificate` always accepts) so that an interception certificate can
/// be examined; detection is based on the issuer, not on chain trust.
///
/// When [resolver] is given the host is resolved through it and the socket is
/// dialed by IP, while the TLS handshake still uses the original hostname for
/// SNI, so the certificate seen is the real one.
Future<CheckResult> check(
  String host, {
  String port = defaultPort,
  Duration timeout = defaultTimeout,
  bool detectFortinet = true,
  bool quick = false,
  HostResolver? resolver,
}) async {
  if (host.isEmpty) {
    return CheckResult(
      host: host,
      status: CheckStatus.invalidInput,
      detail: 'empty or invalid hostname',
    );
  }
  final portNumber = int.tryParse(port) ?? int.parse(defaultPort);
  final effectiveTimeout = timeout > Duration.zero ? timeout : defaultTimeout;

  try {
    final socket = resolver == null
        ? await _connectViaSystem(host, portNumber, effectiveTimeout)
        : await _connectViaResolver(
            host,
            portNumber,
            effectiveTimeout,
            resolver,
          );
    try {
      final certificate = socket.peerCertificate;
      if (certificate == null) {
        return CheckResult(
          host: host,
          status: CheckStatus.tlsOrNetworkError,
          detail: 'server supplied no peer certificate',
        );
      }
      return _inspect(certificate, host, detectFortinet, quick);
    } finally {
      socket.destroy();
    }
  } catch (error) {
    final result = classify(error);
    return CheckResult(
      host: host,
      status: result.status,
      certificateError: result.certificateError,
      detail: compactError(error),
    );
  }
}

/// Resolves with the system resolver and completes the TLS handshake.
Future<SecureSocket> _connectViaSystem(
  String host,
  int port,
  Duration timeout,
) async {
  // `SecureSocket.connect`'s own timeout does not cover DNS resolution or
  // every handshake phase, so a few hosts can hang forever and stall the
  // whole run. `startConnect` yields a cancellable task, and the explicit
  // timeout aborts it no matter where it is stuck.
  final task = await SecureSocket.startConnect(
    host,
    port,
    onBadCertificate: (_) => true,
  );
  return task.socket.timeout(
    timeout,
    onTimeout: () {
      task.cancel();
      throw TimeoutException(
        'connect timed out after ${timeout.inMilliseconds}ms',
        timeout,
      );
    },
  );
}

/// Resolves [host] to an IP through [resolver], then dials that IP and performs
/// the TLS handshake with [host] as SNI.
Future<SecureSocket> _connectViaResolver(
  String host,
  int port,
  Duration timeout,
  HostResolver resolver,
) async {
  final addresses = await resolver.resolve(host).timeout(timeout);
  if (addresses.isEmpty) {
    throw const SocketException('dns lookup returned no address');
  }
  Object? lastError;
  for (final address in addresses) {
    // A bare TCP socket to the resolved IP; the TLS layer is added below with
    // the original hostname so SNI and certificate checks stay correct.
    final socket = await Socket.connect(address, port, timeout: timeout);
    try {
      return await SecureSocket.secure(
        socket,
        host: host,
        onBadCertificate: (_) => true,
      ).timeout(timeout);
    } catch (error) {
      lastError = error;
      socket.destroy();
    }
  }
  throw lastError!;
}

/// Applies the Fortinet/expiry checks to a presented certificate.
CheckResult _inspect(
  X509Certificate certificate,
  String host,
  bool detectFortinet,
  bool quick,
) {
  final issuer = certificate.issuer;
  if (detectFortinet && isFortinetIssuer(issuer)) {
    return CheckResult(
      host: host,
      status: CheckStatus.fortinetBlocked,
      certificateError: 'fortinet_issuer',
      detail: issuer,
    );
  }
  if (quick) {
    // Quick mode only inspects the issuer, not the real server state.
    return CheckResult(
      host: host,
      status: CheckStatus.notFortinet,
      detail: issuer,
    );
  }
  final now = DateTime.now();
  if (certificate.endValidity.isBefore(now)) {
    return CheckResult(
      host: host,
      status: CheckStatus.certificateError,
      certificateError: 'expired',
      detail:
          'certificate expired on '
          '${certificate.endValidity.toIso8601String()}',
    );
  }
  if (certificate.startValidity.isAfter(now)) {
    return CheckResult(
      host: host,
      status: CheckStatus.certificateError,
      certificateError: 'expired',
      detail:
          'certificate not valid until '
          '${certificate.startValidity.toIso8601String()}',
    );
  }
  return CheckResult(
    host: host,
    status: CheckStatus.notFortinet,
    detail: issuer,
  );
}
