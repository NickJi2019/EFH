import 'dart:async';
import 'dart:io';

/// The outcome of probing a single host.
enum CheckStatus {
  /// The server presented a Fortinet-issued certificate.
  fortinetBlocked('fortinet_blocked'),

  /// The certificate was retrieved and no Fortinet issuer matched.
  notFortinet('not_fortinet'),

  /// The TLS handshake failed on certificate validation.
  certificateError('certificate_error'),

  /// The hostname could not be resolved.
  dnsError('dns_error'),

  /// The connection or handshake timed out.
  timeout('timeout'),

  /// The remote refused the connection.
  connectionRefused('connection_refused'),

  /// Any other TLS or network failure.
  tlsOrNetworkError('tls_or_network_error'),

  /// The input row had no usable hostname.
  invalidInput('invalid_input');

  const CheckStatus(this.wire);

  /// The stable string written to the output CSV.
  final String wire;

  @override
  String toString() => wire;
}

/// Reports whether a certificate issuer string identifies Fortinet.
bool isFortinetIssuer(String issuer) =>
    issuer.toLowerCase().contains('fortinet');

/// Rebuilds a [CheckStatus] from its wire string.
CheckStatus statusFromWire(String wire) {
  for (final status in CheckStatus.values) {
    if (status.wire == wire) {
      return status;
    }
  }
  return CheckStatus.tlsOrNetworkError;
}

/// The classification of a dial or TLS handshake failure.
typedef Classification = ({CheckStatus status, String certificateError});

/// Maps a dial or TLS handshake error to a [CheckStatus] and a stable
/// certificate error kind (empty when not a certificate error).
Classification classify(Object error) {
  if (error is HandshakeException) {
    final message = error.message.toUpperCase().replaceAll(RegExp(r'\s+'), '_');
    if (message.contains('SELF_SIGNED') ||
        message.contains('UNKNOWN') ||
        message.contains('UNABLE_TO_VERIFY') ||
        message.contains('UNABLE_TO_GET_ISSUER')) {
      return (
        status: CheckStatus.certificateError,
        certificateError: 'unknown_authority',
      );
    }
    if (message.contains('HOSTNAME')) {
      return (
        status: CheckStatus.certificateError,
        certificateError: 'hostname_mismatch',
      );
    }
    return (
      status: CheckStatus.certificateError,
      certificateError: 'invalid_certificate',
    );
  }
  if (error is TimeoutException) {
    return (status: CheckStatus.timeout, certificateError: '');
  }
  if (error is SocketException) {
    final message = error.message.toLowerCase();
    final code = error.osError?.errorCode;
    if (message.contains('failed host lookup') ||
        message.contains('nodename') ||
        message.contains('name or service not known') ||
        code == 8 /* POSIX ENOENT-ish on some platforms */ ) {
      return (status: CheckStatus.dnsError, certificateError: '');
    }
    if (message.contains('connection refused') ||
        code == 61 /* macOS ECONNREFUSED */ ||
        code == 111 /* Linux ECONNREFUSED */ ||
        code == 10061 /* Windows WSAECONNREFUSED */ ) {
      return (status: CheckStatus.connectionRefused, certificateError: '');
    }
    return (status: CheckStatus.tlsOrNetworkError, certificateError: '');
  }
  return (status: CheckStatus.tlsOrNetworkError, certificateError: '');
}

/// Renders an error as a single CSV-safe line, truncated to 500 characters.
String compactError(Object error) {
  final text = error.toString().replaceAll('\n', ' ');
  if (text.length > 500) {
    return text.substring(0, 500);
  }
  return text;
}
