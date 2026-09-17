import 'dart:async';
import 'dart:io';

import 'package:efh_connectivity_test/connectivity/host.dart';
import 'package:efh_connectivity_test/connectivity/processor.dart';
import 'package:efh_connectivity_test/connectivity/radar.dart';
import 'package:efh_connectivity_test/connectivity/result.dart';
import 'package:efh_connectivity_test/connectivity/status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeHost strips scheme, path and trailing dot', () {
    expect(normalizeHost('Example.COM.'), 'example.com');
    expect(normalizeHost('https://example.com/a'), 'example.com');
    expect(normalizeHost(''), '');
  });

  test('classify maps errors to statuses', () {
    final handshake = classify(
      const HandshakeException('CERTIFICATE_VERIFY_FAILED: self signed'),
    );
    expect(handshake.status, CheckStatus.certificateError);
    expect(handshake.certificateError, 'unknown_authority');

    final dns = classify(
      const SocketException('Failed host lookup: example.com'),
    );
    expect(dns.status, CheckStatus.dnsError);

    final timeout = classify(TimeoutException('timed out'));
    expect(timeout.status, CheckStatus.timeout);

    final refused = classify(const SocketException('Connection refused'));
    expect(refused.status, CheckStatus.connectionRefused);

    final unrelated = classify(StateError('unrelated'));
    expect(unrelated.status, CheckStatus.tlsOrNetworkError);
  });

  test('isFortinetIssuer detects Fortinet and ignores others', () {
    expect(isFortinetIssuer('CN=Fortinet CA, O=Fortinet'), isTrue);
    expect(
      isFortinetIssuer("CN=Let's Encrypt, O=Internet Security Research Group"),
      isFalse,
    );
  });

  test('loadDomainSet normalizes hosts', () async {
    final dir = await Directory.systemTemp.createTemp('efh-test-');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/top.csv';
    await File(path)
        .writeAsString('domain\nExample.COM.\nhttps://discord.com/channels\n');
    final domains = await loadDomainSet(path);
    expect(domains, containsAll(<String>['example.com', 'discord.com']));
  });

  test('parseBucketSelection handles lists, all and errors', () {
    const buckets = [Bucket(200), Bucket(1000), Bucket(10000)];
    final selected = parseBucketSelection('1,3,1', buckets, buckets[2]);
    expect(selected.length, 2);
    expect(selected[0].top, 200);
    expect(selected[1].top, 10000);

    final all = parseBucketSelection('all', buckets, buckets[2]);
    expect(all.length, 3);

    expect(
      () => parseBucketSelection('4', buckets, buckets[2]),
      throwsFormatException,
    );
  });

  test('formatTop inserts thousands separators', () {
    expect(formatTop(200), '200');
    expect(formatTop(2000), '2,000');
    expect(formatTop(1000000), '1,000,000');
  });

  test('readDomainCsv reads and normalizes a domain column', () {
    final domains = readDomainCsv(
      'domain\nExample.COM\nhttps://discord.com/channels\n',
    );
    expect(domains, containsAll(<String>['example.com', 'discord.com']));
  });

  test('parseDomainList reads the EFHServer plain-text list', () {
    final domains = parseDomainList(
      'Example.COM.\nhttps://discord.com/channels\n\n',
    );
    expect(domains.length, 2);
    expect(domains, containsAll(<String>['example.com', 'discord.com']));
  });

  test('process writes invalid_input for a blank host', () async {
    final lines = <String>[];
    final stats = await process(
      'domain,label\n,blank\n',
      onRow: lines.add,
      options: const Options(workers: 1, timeout: Duration(milliseconds: 1)),
    );
    expect(stats.total, 1);
    expect(stats.processed, 1);
    expect(
      lines.join(),
      'domain,label,check_status,certificate_error,check_detail\n'
      ',blank,invalid_input,,empty or invalid hostname\n',
    );
  });

  test('process reports live stats through onStats', () async {
    final snapshots = <Stats>[];
    final stats = await process(
      'domain,label\n,blank\n',
      onRow: (_) {},
      onStats: snapshots.add,
      options: const Options(workers: 1, timeout: Duration(milliseconds: 1)),
    );

    expect(snapshots, isNotEmpty);
    expect(stats.total, 1);
    expect(stats.processed, 1);
    expect(stats.notFortinet, 0);
    expect(stats.fortinetBlocked, 0);
    expect(stats.failed, 1);
  });

  test('process reports each result through onResult', () async {
    final results = <CheckResult>[];
    await process(
      'domain\n,blank\n',
      onRow: (_) {},
      onResult: results.add,
      options: const Options(workers: 1, timeout: Duration(milliseconds: 1)),
    );

    expect(results, hasLength(1));
    expect(results.single.status, CheckStatus.invalidInput);
  });

  test('process reports start before the matching result', () async {
    final events = <String>[];
    await process(
      'domain\n,blank\n',
      onRow: (_) {},
      onStart: (seq, host) => events.add('start:$seq:$host'),
      onResult: (result) => events.add('result:${result.status.wire}'),
      options: const Options(workers: 1, timeout: Duration(milliseconds: 1)),
    );

    expect(events, ['start:0:', 'result:invalid_input']);
  });

  test('writeDomainCsv writes a sorted domain list', () {
    expect(writeDomainCsv({'b.com', 'a.com'}), 'domain\na.com\nb.com\n');
  });

  test('cancelToken completes onCancel when cancelled', () async {
    final token = CancelToken();
    expect(token.isCancelled, isFalse);

    var notified = false;
    unawaited(token.onCancel.then((_) => notified = true));

    token.cancel();
    await token.onCancel;

    expect(token.isCancelled, isTrue);
    expect(notified, isTrue);
  });

  test('pauseToken holds waiters until resumed', () async {
    final token = PauseToken();
    expect(token.isPaused, isFalse);
    await token.waitResumed();

    token.pause();
    expect(token.isPaused, isTrue);

    var resumed = false;
    unawaited(token.waitResumed().then((_) => resumed = true));
    await Future<void>.delayed(Duration.zero);
    expect(resumed, isFalse);

    token.resume();
    await token.waitResumed();
    expect(resumed, isTrue);
    expect(token.isPaused, isFalse);
  });

  test('process keeps running after resume', () async {
    final calls = <String>[];
    final reverted = <int>[];
    final cancel = CancelToken();
    final pause = PauseToken();

    Future<CheckResult> probe(
      String host, {
      String port = '',
      Duration timeout = Duration.zero,
      bool detectFortinet = true,
      bool quick = false,
    }) {
      calls.add(host);
      // Never completes on its own; it is interrupted by pause / cancel.
      return Completer<CheckResult>().future;
    }

    final future = process(
      'domain\na\nb\n',
      onRow: (_) {},
      onRevert: reverted.add,
      options: const Options(workers: 1),
      cancelToken: cancel,
      pauseToken: pause,
      probe: probe,
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(calls, ['a']);

    pause.pause();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // The in-flight probe should have been interrupted and put back.
    expect(reverted, isNotEmpty);

    pause.resume();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    // The scheduler must run again after resuming.
    expect(calls.length, greaterThanOrEqualTo(2));

    cancel.cancel();
    await future.timeout(const Duration(seconds: 2));
  });
}
