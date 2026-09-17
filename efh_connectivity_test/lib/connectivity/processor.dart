import 'dart:async';
import 'dart:io';

import 'checker.dart';
import 'csv_codec.dart';
import 'host.dart';
import 'reporter.dart';
import 'result.dart';
import 'status.dart';

/// Controls a processing run.
class Options {
  const Options({
    this.port = defaultPort,
    this.workers = defaultWorkers,
    this.timeout = defaultTimeout,
    this.onlyFortinet = false,
    this.detectFortinet = true,
    this.quickCheck = false,
    this.logDomains,
    this.logLabel = '',
  });

  /// The TLS port to probe.
  final String port;

  /// The probe concurrency; zero or less means [defaultWorkers].
  final int workers;

  /// The per-host timeout; zero or less means [defaultTimeout].
  final Duration timeout;

  /// Drops non-Fortinet rows from the output when true.
  final bool onlyFortinet;

  /// Whether a Fortinet-issued certificate is flagged as blocked.
  final bool detectFortinet;

  /// Whether to only inspect the certificate issuer (no other checks).
  final bool quickCheck;

  /// Limits [Reporter.alert] to these hosts; null logs everything.
  final Set<String>? logDomains;

  /// Names the log domain set in alerts.
  final String logLabel;

  Options copyWith({
    String? port,
    int? workers,
    Duration? timeout,
    bool? onlyFortinet,
    bool? detectFortinet,
    bool? quickCheck,
    Set<String>? logDomains,
    String? logLabel,
  }) {
    return Options(
      port: port ?? this.port,
      workers: workers ?? this.workers,
      timeout: timeout ?? this.timeout,
      onlyFortinet: onlyFortinet ?? this.onlyFortinet,
      detectFortinet: detectFortinet ?? this.detectFortinet,
      quickCheck: quickCheck ?? this.quickCheck,
      logDomains: logDomains ?? this.logDomains,
      logLabel: logLabel ?? this.logLabel,
    );
  }

  Options normalized() {
    return Options(
      port: port.isEmpty ? defaultPort : port,
      workers: workers <= 0 ? defaultWorkers : workers,
      timeout: timeout <= Duration.zero ? defaultTimeout : timeout,
      onlyFortinet: onlyFortinet,
      detectFortinet: detectFortinet,
      quickCheck: quickCheck,
      logDomains: logDomains,
      logLabel: logLabel,
    );
  }
}

/// Signature of a probe, matching [check]; injectable for tests.
typedef Probe = Future<CheckResult> Function(
  String host, {
  String port,
  Duration timeout,
  bool detectFortinet,
  bool quick,
});

/// A cooperative cancellation flag shared with a running [process] call.
///
/// In-flight probes race against [onCancel], so cancelling makes [process]
/// return promptly instead of waiting for every probe's timeout.
class CancelToken {
  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;

  /// Completes as soon as [cancel] is called (or immediately if already
  /// cancelled). Handy for racing against long-running futures.
  Future<void> get onCancel => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
}

class _Job {
  _Job(this.seq, this.record, this.host);

  final int seq;
  final List<String> record;
  final String host;
}

/// A cooperative pause flag shared with a running [process] call. While paused
/// no new probes start; in-flight probes are aborted at once and the caller is
/// told to put them back with [onRevert].
class PauseToken {
  bool _paused = false;
  Completer<void> _resume = Completer<void>()..complete();
  Completer<void> _pauseSignal = Completer<void>();

  bool get isPaused => _paused;

  /// Completes the next time [pause] is called.
  Future<void> get onPause => _pauseSignal.future;

  void pause() {
    if (_paused) {
      return;
    }
    _paused = true;
    _resume = Completer<void>();
    if (!_pauseSignal.isCompleted) {
      _pauseSignal.complete();
    }
  }

  void resume() {
    if (!_paused) {
      return;
    }
    _paused = false;
    if (!_resume.isCompleted) {
      _resume.complete();
    }
    _pauseSignal = Completer<void>();
  }

  /// Completes immediately unless paused, otherwise when [resume] is called.
  Future<void> waitResumed() => _resume.future;
}

enum _OutcomeSignal { cancelled, paused }

/// Counts the data rows of a CSV, excluding its header.
int countRecords(String csv) {
  final rows = parseCsv(csv);
  if (rows.isEmpty) {
    throw const FormatException('read CSV header: EOF');
  }
  return rows.length - 1;
}

/// Reads a domain list from a CSV with a recognized domain column.
Set<String> readDomainCsv(String csv) {
  final rows = parseCsv(csv);
  if (rows.isEmpty) {
    throw const FormatException('missing CSV header');
  }
  final column = findDomainColumn(rows.first);
  if (column < 0) {
    throw const FormatException('expected a domain CSV');
  }
  final domains = <String>{};
  for (var i = 1; i < rows.length; i++) {
    final record = rows[i];
    if (column < record.length) {
      final host = normalizeHost(record[column]);
      if (host.isNotEmpty) {
        domains.add(host);
      }
    }
  }
  return domains;
}

/// Reads a domain list from a file path.
Future<Set<String>> loadDomainSet(String path) async {
  final csv = await File(path).readAsString();
  final rows = parseCsv(csv);
  if (rows.isEmpty) {
    throw const FormatException('read CSV header: EOF');
  }
  final column = findDomainColumn(rows.first);
  if (column < 0) {
    throw const FormatException(
      'CSV needs a domain, host, hostname, url, or website column',
    );
  }
  final domains = <String>{};
  for (var i = 1; i < rows.length; i++) {
    final record = rows[i];
    if (column < record.length) {
      final host = normalizeHost(record[column]);
      if (host.isNotEmpty) {
        domains.add(host);
      }
    }
  }
  return domains;
}

/// Returns the set as a deterministic sorted list.
List<String> sortedDomains(Set<String> set) {
  final domains = set.toList()..sort();
  return domains;
}

/// Writes a `domain` CSV from a set, in sorted order.
String writeDomainCsv(Set<String> domains) {
  final buffer = StringBuffer();
  buffer.write(encodeCsvRow(const ['domain']));
  for (final domain in sortedDomains(domains)) {
    buffer.write(encodeCsvRow([domain]));
  }
  return buffer.toString();
}

/// Reads [inputCsv], probes every row, and hands the original columns plus
/// `check_status`, `certificate_error` and `check_detail` to [onRow] in input
/// order.
///
/// Results complete out of order; only a bounded window is buffered so the
/// output stays joinable with the input. [onRow] receives each finished CSV
/// line, including the header, exactly once. [onStats] is called with the live
/// counters as each probe finishes, so callers can show progress by outcome.
Future<Stats> process(
  String inputCsv, {
  required void Function(String line) onRow,
  void Function(Stats stats)? onStats,
  void Function(int seq, String host)? onStart,
  void Function(CheckResult result)? onResult,
  void Function(int seq)? onRevert,
  Probe? probe,
  Options options = const Options(),
  Reporter reporter = const NopReporter(),
  CancelToken? cancelToken,
  PauseToken? pauseToken,
}) async {
  final o = options.normalized();
  final token = cancelToken ?? CancelToken();
  final runProbe = probe ?? check;

  final rows = parseCsv(inputCsv);
  if (rows.isEmpty) {
    throw const FormatException('read CSV header: EOF');
  }
  final header = rows.first;
  final column = findDomainColumn(header);
  if (column < 0) {
    throw const FormatException(
      'CSV needs a domain, host, hostname, url, or website column',
    );
  }

  final jobs = <_Job>[];
  for (var i = 1; i < rows.length; i++) {
    final record = rows[i];
    final host = column < record.length ? normalizeHost(record[column]) : '';
    jobs.add(_Job(i - 1, record, host));
  }
  final total = jobs.length;
  final stats = Stats(total: total);

  onRow(
    encodeCsvRow([
      ...header,
      'check_status',
      'certificate_error',
      'check_detail',
    ]),
  );
  reporter.progress(0, total);

  final pending = <int, CheckResult>{};
  final finished = Completer<void>();
  var next = 0;
  var cursor = 0;
  var active = 0;

  void flushOrdered() {
    while (pending.containsKey(next)) {
      final result = pending.remove(next)!;
      if (!o.onlyFortinet || result.status == CheckStatus.fortinetBlocked) {
        onRow(
          encodeCsvRow([
            ...result.record,
            result.status.wire,
            result.certificateError,
            result.detail,
          ]),
        );
      }
      next++;
      reporter.progress(next, total);
    }
  }

  late void Function() startJobs;
  var scheduling = false;
  const maxBatch = 256;

  Future<void> runJob(_Job job) async {
    onStart?.call(job.seq, job.host);
    // Race the probe against cancellation and pause so neither has to wait for
    // the probe's timeout. A losing probe keeps running in the background but
    // its result is discarded.
    final outcome = await Future.any<Object?>([
      runProbe(
        job.host,
        port: o.port,
        timeout: o.timeout,
        detectFortinet: o.detectFortinet,
        quick: o.quickCheck,
      ).timeout(
        // Last-resort guard: even if the underlying connect hangs in a way the
        // probe's own timeout cannot interrupt, the job still completes.
        o.timeout + const Duration(seconds: 2),
        onTimeout: () => CheckResult(
          host: job.host,
          status: CheckStatus.timeout,
          detail: 'probe exceeded its timeout',
        ),
      ),
      token.onCancel.then((_) => _OutcomeSignal.cancelled),
      if (pauseToken != null)
        pauseToken.onPause.then((_) => _OutcomeSignal.paused),
    ]);

    active--;
    if (outcome == _OutcomeSignal.cancelled) {
      if (active == 0 && !finished.isCompleted) {
        finished.complete();
      }
      return;
    }
    if (outcome == _OutcomeSignal.paused) {
      // The probe was interrupted by a pause: put the domain back and wait.
      onRevert?.call(job.seq);
      jobs.add(job);
      await pauseToken!.waitResumed();
      if (token.isCancelled) {
        if (active == 0 && !finished.isCompleted) {
          finished.complete();
        }
        return;
      }
      if (cursor >= jobs.length && active == 0) {
        if (!finished.isCompleted) {
          finished.complete();
        }
        return;
      }
      startJobs();
      return;
    }

    final probe = outcome as CheckResult;
    final result = probe.copyWith(
      seq: job.seq,
      record: job.record,
      host: job.host,
    );

    if (result.status == CheckStatus.fortinetBlocked &&
        (o.logDomains == null || o.logDomains!.contains(result.host))) {
      reporter.alert(result);
    }
    if (result.status == CheckStatus.fortinetBlocked) {
      stats.fortinetBlocked++;
    } else if (result.status == CheckStatus.notFortinet) {
      stats.notFortinet++;
    } else if (result.status == CheckStatus.certificateError) {
      stats.certificateError++;
    } else {
      stats.failed++;
    }
    stats.processed++;
    onStats?.call(stats);
    onResult?.call(result);

    pending[result.seq] = result;
    flushOrdered();

    if (token.isCancelled) {
      if (active == 0 && !finished.isCompleted) {
        finished.complete();
      }
      return;
    }
    if (pauseToken?.isPaused ?? false) {
      await pauseToken!.waitResumed();
      if (token.isCancelled) {
        if (active == 0 && !finished.isCompleted) {
          finished.complete();
        }
        return;
      }
    }
    if (cursor >= jobs.length && active == 0) {
      if (!finished.isCompleted) {
        finished.complete();
      }
      return;
    }
    startJobs();
  }

  void pump() {
    if (scheduling || finished.isCompleted || token.isCancelled) {
      return;
    }
    scheduling = true;
    // Yield to the event loop between batches so a large concurrency does not
    // freeze the UI while probes are launched.
    Future<void>.delayed(Duration.zero, () {
      scheduling = false;
      var budget = maxBatch;
      while (budget-- > 0 &&
          !token.isCancelled &&
          !(pauseToken?.isPaused ?? false) &&
          active < o.workers &&
          cursor < jobs.length) {
        final job = jobs[cursor++];
        active++;
        unawaited(runJob(job));
      }
      if (!token.isCancelled &&
          !(pauseToken?.isPaused ?? false) &&
          cursor < jobs.length &&
          active < o.workers) {
        pump();
      }
    });
  }

  startJobs = pump;

  // Watchdog: when the run is resumed, always kick the scheduler again, even
  // if no in-flight probe happened to be waiting at that moment.
  if (pauseToken != null) {
    final pause = pauseToken;
    unawaited(() async {
      while (!finished.isCompleted && !token.isCancelled) {
        await pause.onPause;
        await pause.waitResumed();
        if (finished.isCompleted || token.isCancelled) {
          return;
        }
        startJobs();
      }
    }());
  }

  if (jobs.isEmpty) {
    finished.complete();
  } else {
    startJobs();
  }

  await finished.future;
  reporter.progress(next, total);
  return stats;
}

/// Runs [process] over an input path.
Future<Stats> processFile(
  String inputPath, {
  required void Function(String line) onRow,
  void Function(Stats stats)? onStats,
  void Function(int seq, String host)? onStart,
  void Function(CheckResult result)? onResult,
  void Function(int seq)? onRevert,
  Probe? probe,
  Options options = const Options(),
  Reporter reporter = const NopReporter(),
  CancelToken? cancelToken,
  PauseToken? pauseToken,
}) async {
  final input = await File(inputPath).readAsString();
  return process(
    input,
    onRow: onRow,
    onStats: onStats,
    onStart: onStart,
    onResult: onResult,
    onRevert: onRevert,
    probe: probe,
    options: options,
    reporter: reporter,
    cancelToken: cancelToken,
    pauseToken: pauseToken,
  );
}

/// Runs [process] over an in-memory domain set.
Future<Stats> processDomains(
  Set<String> domains, {
  required void Function(String line) onRow,
  void Function(Stats stats)? onStats,
  void Function(int seq, String host)? onStart,
  void Function(CheckResult result)? onResult,
  void Function(int seq)? onRevert,
  Probe? probe,
  Options options = const Options(),
  Reporter reporter = const NopReporter(),
  CancelToken? cancelToken,
  PauseToken? pauseToken,
}) {
  return process(
    writeDomainCsv(domains),
    onRow: onRow,
    onStats: onStats,
    onStart: onStart,
    onResult: onResult,
    onRevert: onRevert,
    probe: probe,
    options: options,
    reporter: reporter,
    cancelToken: cancelToken,
    pauseToken: pauseToken,
  );
}
