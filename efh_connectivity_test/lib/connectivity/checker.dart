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

/// Dials `host:port` and inspects the leaf certificate.
///
/// The handshake deliberately permits an untrusted certificate
/// (`onBadCertificate` always accepts) so that an interception certificate can
/// be examined; detection is based on the issuer, not on chain trust.
Future<CheckResult> check(
  String host, {
  String port = defaultPort,
  Duration timeout = defaultTimeout,
  bool detectFortinet = true,
  bool quick = false,
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
    // `SecureSocket.connect`'s own timeout does not cover DNS resolution or
    // every handshake phase, so a few hosts can hang forever and stall the
    // whole run. `startConnect` yields a cancellable task, and the explicit
    // timeout aborts it no matter where it is stuck.
    final task = await SecureSocket.startConnect(
      host,
      portNumber,
      onBadCertificate: (_) => true,
    );
    final socket = await task.socket.timeout(
      effectiveTimeout,
      onTimeout: () {
        task.cancel();
        throw TimeoutException(
          'connect timed out after ${effectiveTimeout.inMilliseconds}ms',
          effectiveTimeout,
        );
      },
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
