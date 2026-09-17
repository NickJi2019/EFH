import 'dart:isolate';

import 'processor.dart';

/// Isolate entry point that runs all probes off the UI thread and streams
/// batched events back to the main isolate.
///
/// [args] is `[config, mainSendPort]`, where `config` holds the input CSV and
/// the run options. Control messages (`cancel` / `pause` / `resume`) arrive on
/// the control port announced via a `control` message.
Future<void> probeWorkerEntry(List<Object?> args) async {
  final config = (args[0] as Map).cast<String, Object?>();
  final mainSend = args[1] as SendPort;

  final control = ReceivePort();
  mainSend.send({'type': 'control', 'port': control.sendPort});

  final cancel = CancelToken();
  final pause = PauseToken();
  control.listen((message) {
    if (message is Map) {
      switch (message['type']) {
        case 'cancel':
          // Release any paused waiters so the run can wind down.
          cancel.cancel();
          pause.resume();
        case 'pause':
          pause.pause();
        case 'resume':
          pause.resume();
      }
    }
  });

  final starts = <Map<String, Object?>>[];
  final results = <Map<String, Object?>>[];
  final reverts = <int>[];
  Map<String, Object?>? statsSnapshot;
  var lastFlush = DateTime.now();

  void flush({bool force = false}) {
    final elapsed = DateTime.now().difference(lastFlush).inMilliseconds;
    if (!force) {
      if (starts.isEmpty &&
          results.isEmpty &&
          reverts.isEmpty &&
          statsSnapshot == null) {
        return;
      }
      if (starts.length + results.length + reverts.length < 128 &&
          elapsed < 120) {
        return;
      }
    }
    lastFlush = DateTime.now();
    if (starts.isNotEmpty || results.isNotEmpty) {
      mainSend.send({
        'type': 'batch',
        'starts': starts.toList(),
        'results': results.toList(),
      });
      starts.clear();
      results.clear();
    }
    if (reverts.isNotEmpty) {
      // Pausing can interrupt every in-flight probe at once; send them as one
      // message instead of one per host.
      mainSend.send({'type': 'revert', 'seqs': reverts.toList()});
      reverts.clear();
    }
    final snapshot = statsSnapshot;
    if (snapshot != null) {
      mainSend.send({'type': 'stats', ...snapshot});
      statsSnapshot = null;
    }
  }

  try {
    final stats = await process(
      config['csv'] as String,
      onRow: (_) {},
      onStats: (stats) {
        statsSnapshot = {
          'total': stats.total,
          'processed': stats.processed,
          'fortinet': stats.fortinetBlocked,
          'notFortinet': stats.notFortinet,
          'cert': stats.certificateError,
          'failed': stats.failed,
        };
        flush();
      },
      onStart: (seq, host) {
        starts.add({'seq': seq, 'host': host});
        flush();
      },
      onRevert: (seq) {
        reverts.add(seq);
        flush();
      },
      onResult: (result) {
        results.add({
          'seq': result.seq,
          'host': result.host,
          'status': result.status.wire,
          'certificateError': result.certificateError,
          'detail': result.detail,
        });
        flush();
      },
      options: Options(
        workers: config['workers'] as int,
        timeout: Duration(seconds: config['timeout'] as int),
        detectFortinet: config['detectFortinet'] as bool,
        quickCheck: config['quickCheck'] as bool,
      ),
      cancelToken: cancel,
      pauseToken: pause,
    );
    flush(force: true);
    mainSend.send({
      'type': 'done',
      'total': stats.total,
      'processed': stats.processed,
      'fortinet': stats.fortinetBlocked,
      'notFortinet': stats.notFortinet,
      'cert': stats.certificateError,
      'failed': stats.failed,
    });
  } catch (exception) {
    flush(force: true);
    mainSend.send({'type': 'error', 'message': '$exception'});
  }
}
