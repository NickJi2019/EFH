import 'status.dart';

/// The check outcome for a single input row.
class CheckResult {
  CheckResult({
    this.seq = 0,
    this.record = const [],
    this.host = '',
    this.status = CheckStatus.invalidInput,
    this.certificateError = '',
    this.detail = '',
  });

  /// The zero-based row index, used to restore input order.
  final int seq;

  /// The original CSV row.
  final List<String> record;

  /// The normalized hostname that was checked.
  final String host;

  /// The classification of the probe.
  final CheckStatus status;

  /// A stable kind when [status] is [CheckStatus.certificateError] or
  /// `fortinet_issuer` when a Fortinet certificate was found.
  final String certificateError;

  /// The issuer string, the error text, or an explanatory note.
  final String detail;

  CheckResult copyWith({
    int? seq,
    List<String>? record,
    String? host,
    CheckStatus? status,
    String? certificateError,
    String? detail,
  }) {
    return CheckResult(
      seq: seq ?? this.seq,
      record: record ?? this.record,
      host: host ?? this.host,
      status: status ?? this.status,
      certificateError: certificateError ?? this.certificateError,
      detail: detail ?? this.detail,
    );
  }
}

/// Summarizes a processing run.
class Stats {
  Stats({
    this.total = 0,
    this.processed = 0,
    this.fortinetBlocked = 0,
    this.notFortinet = 0,
    this.certificateError = 0,
    this.failed = 0,
  });

  int total;
  int processed;
  int fortinetBlocked;

  /// Hosts that completed the handshake with a non-Fortinet certificate.
  int notFortinet;
  int certificateError;
  int failed;
}
