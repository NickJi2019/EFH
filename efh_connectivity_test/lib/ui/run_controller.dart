import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../connectivity/list_cache.dart';
import '../connectivity/probe_worker.dart';
import '../connectivity/processor.dart';
import '../connectivity/radar.dart';
import '../connectivity/reporter.dart';
import '../connectivity/result.dart';
import '../connectivity/app_version.dart';
import '../connectivity/settings_store.dart';
import '../connectivity/status.dart';
import '../connectivity/update_checker.dart';
import '../l10n/app_localizations.dart';

/// Which source the probes are run against.
enum DataSource { radar, local }

/// One probed domain, shown as a row in the log. Created when the probe
/// starts, then filled in when it finishes.
class ResultItem {
  ResultItem.pending({
    required this.seq,
    required this.host,
    required this.top,
  });

  final int seq;
  final String host;

  /// The smallest Top-N list this host belongs to, or [RunController.selectedTop]
  /// when it is unknown.
  final int top;

  /// The probe outcome; null while the probe is still running.
  CheckStatus? status;
  String detail = '';
  String certificateError = '';

  bool get done => status != null;

  bool get blocked => status == CheckStatus.fortinetBlocked;

  bool get otherError {
    final value = status;
    return value != null &&
        value != CheckStatus.notFortinet &&
        value != CheckStatus.fortinetBlocked &&
        value != CheckStatus.invalidInput;
  }

  /// A human-readable description of the failure, for the log row.
  String get errorText {
    if (detail.trim().isNotEmpty) {
      return detail.trim();
    }
    if (certificateError.trim().isNotEmpty) {
      return certificateError.trim();
    }
    return status?.wire ?? '';
  }
}

/// Owns the configuration and the lifecycle of a run, and notifies listeners
/// (the views) as progress, matches and results arrive.
class RunController extends ChangeNotifier implements Reporter {
  RunController({Locale? initialLocale, this.autoWarmUp = true})
    : locale = initialLocale {
    _loadSettings();
    unawaited(_detectSystemColorSupport());
  }

  /// Whether the shell should refresh the cached lists on startup.
  final bool autoWarmUp;

  static const int maxResults = 200000;
  static const int _maxHeatEntries = 2000000;
  static const String defaultWorkersText = '200';

  // ---------------------------------------------------------------- 配置
  DataSource source = DataSource.radar;

  /// Where the cached Top-N lists come from. Fixed to [efhServerBaseUrl] for
  /// the EFHServer source.
  RadarSource radarSource = RadarSource.efhServer;

  /// The single Top-N list to check.
  int selectedTop = 200;

  String inputPath = '';
  String workersText = defaultWorkersText;
  String timeoutText = '8';
  bool hdsbDetection = true;

  /// Quick HDSB check: only inspector the issuer, skip other checks.
  bool hdsbQuickCheck = false;

  /// Radar API token; only ever read from the settings, never the environment.
  String cfToken = '';

  /// UI locale; null means follow the system locale.
  Locale? locale;

  /// Whether to follow the system's light/dark mode.
  bool followSystemDark = true;

  /// Explicit dark mode when not following the system; ignored otherwise.
  bool darkMode = false;

  /// The effective theme mode.
  ThemeMode get resolvedThemeMode => followSystemDark
      ? ThemeMode.system
      : (darkMode ? ThemeMode.dark : ThemeMode.light);

  /// Accent seed color; null uses the default.
  Color? seedColor;

  /// Whether to follow the system's dynamic accent color when available.
  bool followSystemColor = true;

  /// Whether the current platform provides a system accent color.
  bool supportsSystemColor = true;

  /// Injected by the shell so logs and validation messages are localized.
  late AppLocalizations l10n;

  // ---------------------------------------------------------------- 运行态
  bool running = false;

  /// Whether the last run ended because the user cancelled it.
  bool cancelled = false;
  int done = 0;
  int total = 0;
  DateTime? startedAt;
  Stats? stats;
  String? error;

  /// The latest non-prerelease release found on GitHub, if any.
  ReleaseInfo? latestRelease;
  bool checkingUpdates = false;
  bool updateCheckFailed = false;
  DateTime? updateCheckedAt;

  /// Whether a newer client version is available.
  bool get updateAvailable {
    final release = latestRelease;
    return release != null && isNewerVersion(release.tag, appVersion);
  }

  /// Checks GitHub for a newer release. Prereleases are ignored because they
  /// are used for the server.
  Future<void> checkForUpdates() async {
    if (checkingUpdates) {
      return;
    }
    checkingUpdates = true;
    updateCheckFailed = false;
    notifyListeners();
    final release = await UpdateChecker().fetchLatest();
    checkingUpdates = false;
    if (release == null) {
      updateCheckFailed = true;
    } else {
      latestRelease = release;
    }
    updateCheckedAt = DateTime.now();
    notifyListeners();
  }

  /// Short human-readable status shown on the progress card.
  String? statusMessage;
  bool warmingUp = false;
  DateTime? listsUpdatedAt;
  int listUpdateDone = 0;
  int listUpdateTotal = 0;

  /// Progress (0..1) of the list refresh, for the manual update bar.
  double get listUpdateProgress =>
      listUpdateTotal > 0 ? listUpdateDone / listUpdateTotal : 0;

  /// Probes that are currently running, newest first.
  final List<ResultItem> pending = [];

  /// Probes that have started at least once (kept for progress only, so the
  /// "started" layer never shrinks when a pause reverts in-flight probes).
  final Set<int> _startedSeqs = {};

  /// Finished probes, in completion order.
  final List<ResultItem> completed = [];

  final Map<int, ResultItem> _pendingBySeq = {};

  bool autoScroll = true;

  final ListCache _cache = ListCache();
  final SettingsStore _settings = SettingsStore();
  Map<String, int> _minTop = const {};

  CancelToken? _cancelToken;
  PauseToken? _pauseToken;
  SendPort? _isolateControl;
  final List<Map<String, Object?>> _pendingControl = [];
  HttpClient? _httpClient;
  Timer? _notifyTimer;
  Timer? _saveTimer;
  Timer? _revisionTimer;
  bool _revisionDirty = false;
  DateTime? _lastProgressAt;

  /// Bumped (throttled) whenever the result list content changes, so the log
  /// view can rebuild independently of high-frequency progress updates.
  final ValueNotifier<int> resultsRevision = ValueNotifier<int>(0);

  /// Whether the run is currently paused.
  bool get paused => _pauseToken?.isPaused ?? false;

  double get rate {
    final started = startedAt;
    if (started == null) {
      return 0;
    }
    final seconds = DateTime.now().difference(started).inMilliseconds / 1000.0;
    if (seconds <= 0) {
      return 0;
    }
    return done / seconds;
  }

  double get progressValue => total > 0 ? done / total : 0;

  /// Fraction of domains whose probe has started; never shrinks on pause.
  double get startedProgress => total > 0 ? _startedSeqs.length / total : 0;

  /// Fraction of domains whose probe has finished.
  double get completedProgress => total > 0 ? completed.length / total : 0;

  /// Whether there is a finished result set worth exporting.
  bool get hasResults => completed.isNotEmpty;

  /// The Top-N heat of a host, falling back to the checked list.
  int heatFor(String host) => _minTop[host] ?? selectedTop;

  void _loadSettings() {
    final data = _settings.readSync();
    if (data == null) {
      return;
    }
    final top = data['selectedTop'];
    if (top is int && findBucket(top) != null) {
      selectedTop = top;
    }
    final token = data['cfToken'];
    if (token is String) {
      cfToken = token;
    }
    final radar = data['radarSource'];
    if (radar is String) {
      for (final value in RadarSource.values) {
        if (value.name == radar) {
          radarSource = value;
        }
      }
    }
    final hdsb = data['hdsbDetection'] ?? data['onlyFortinet'];
    if (hdsb is bool) {
      hdsbDetection = hdsb;
    }
    final quick = data['hdsbQuickCheck'];
    if (quick is bool) {
      hdsbQuickCheck = quick;
    }
    final workers = data['workersText'];
    if (workers is String && workers.trim().isNotEmpty) {
      workersText = workers;
    }
    final timeout = data['timeoutText'];
    if (timeout is String && timeout.trim().isNotEmpty) {
      timeoutText = timeout;
    }
    final followDark = data['followSystemDark'];
    if (followDark is bool) {
      followSystemDark = followDark;
    }
    final dark = data['darkMode'];
    if (dark is bool) {
      darkMode = dark;
    }
    final legacyMode = data['themeMode'];
    if (legacyMode is String && followDark is! bool) {
      if (legacyMode == 'dark') {
        followSystemDark = false;
        darkMode = true;
      } else if (legacyMode == 'light') {
        followSystemDark = false;
        darkMode = false;
      }
    }
    final seed = data['seedColor'];
    if (seed is int) {
      seedColor = Color(seed);
    }
    final follow = data['followSystemColor'];
    if (follow is bool) {
      followSystemColor = follow;
    }
  }

  void _scheduleSave() {
    _saveTimer ??= Timer(const Duration(milliseconds: 400), () {
      _saveTimer = null;
      _settings.write({
        'selectedTop': selectedTop,
        'cfToken': cfToken,
        'radarSource': radarSource.name,
        'hdsbDetection': hdsbDetection,
        'hdsbQuickCheck': hdsbQuickCheck,
        'workersText': workersText,
        'timeoutText': timeoutText,
        'followSystemDark': followSystemDark,
        'darkMode': darkMode,
        'seedColor': seedColor?.toARGB32(),
        'followSystemColor': followSystemColor,
      });
    });
  }

  // ---------------------------------------------------------------- 配置更新
  void setSource(DataSource value) {
    source = value;
    notifyListeners();
  }

  void setRadarSource(RadarSource value) {
    radarSource = value;
    _scheduleSave();
    notifyListeners();
  }

  void setSelectedTop(int top) {
    selectedTop = top;
    _scheduleSave();
    notifyListeners();
  }

  void setInputPath(String value) {
    inputPath = value;
    notifyListeners();
  }

  void setWorkersText(String value) {
    workersText = value;
    _scheduleSave();
  }

  void setTimeoutText(String value) {
    timeoutText = value;
    _scheduleSave();
  }

  void setHdsbDetection(bool value) {
    hdsbDetection = value;
    _scheduleSave();
    _requestResultsRefresh(immediate: true);
    notifyListeners();
  }

  void setHdsbQuickCheck(bool value) {
    hdsbQuickCheck = value;
    _scheduleSave();
    _requestResultsRefresh(immediate: true);
    notifyListeners();
  }

  void setAutoScroll(bool value) {
    autoScroll = value;
    notifyListeners();
  }

  void setCfToken(String value) {
    cfToken = value;
    _scheduleSave();
  }

  void setLocale(Locale? value) {
    locale = value;
    notifyListeners();
  }

  void setFollowSystemDark(bool value) {
    followSystemDark = value;
    _scheduleSave();
    notifyListeners();
  }

  void setDarkMode(bool value) {
    darkMode = value;
    _scheduleSave();
    notifyListeners();
  }

  void setSeedColor(Color? value) {
    seedColor = value;
    _scheduleSave();
    notifyListeners();
  }

  void setFollowSystemColor(bool value) {
    if (value && !supportsSystemColor) {
      return;
    }
    followSystemColor = value;
    _scheduleSave();
    notifyListeners();
  }

  Future<void> _detectSystemColorSupport() async {
    bool supported;
    try {
      supported = await DynamicColorPlugin.getAccentColor() != null;
    } catch (_) {
      supported = false;
    }
    if (supported == supportsSystemColor && (supported || !followSystemColor)) {
      return;
    }
    supportsSystemColor = supported;
    if (!supported) {
      followSystemColor = false;
    }
    _scheduleSave();
    notifyListeners();
  }

  /// Opens the system file picker and stores the chosen CSV path.
  Future<String?> pickInputFile() async {
    await FilePicker.skipEntitlementsChecks();
    final files = await FilePicker.pickFiles(
      dialogTitle: l10n.pickFileTitle,
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
    );
    if (files.isEmpty) {
      return null;
    }
    final path = files.single.path;
    if (path == null) {
      return null;
    }
    setInputPath(path);
    return path;
  }

  /// Writes the finished results to a user-chosen JSON file.
  ///
  /// Returns the saved path, or null when there is nothing to export or the
  /// user cancels.
  Future<String?> exportJson() async {
    if (completed.isEmpty) {
      return null;
    }
    await FilePicker.skipEntitlementsChecks();
    final data = [
      for (final item in completed)
        <String, Object?>{
          'host': item.host,
          'status': item.status?.wire ?? 'pending',
          'top': item.top,
          if (item.certificateError.isNotEmpty)
            'certificateError': item.certificateError,
          if (item.detail.isNotEmpty) 'detail': item.detail,
        },
    ];
    final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(data));
    final uri = await FilePicker.saveFile(
      dialogTitle: l10n.exportDialogTitle,
      fileName: 'results.json',
      bytes: Uint8List.fromList(bytes),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (uri == null) {
      return null;
    }
    return uri.scheme == 'file' ? uri.toFilePath() : uri.toString();
  }

  void clearResults() {
    pending.clear();
    completed.clear();
    _pendingBySeq.clear();
    _startedSeqs.clear();
    _requestResultsRefresh(immediate: true);
    notifyListeners();
  }

  // ---------------------------------------------------------------- 列表缓存
  /// Ensures every Top-N list is cached and younger than seven days, then
  /// rebuilds the host -> smallest-Top index used for heat filtering.
  Future<void> refreshLists({bool force = false}) async {
    if (warmingUp) {
      return;
    }
    warmingUp = true;
    final startedAt = DateTime.now();
    listUpdateDone = 0;
    listUpdateTotal = rankingBuckets.length;
    statusMessage = l10n.listUpdating(l10n.sourceRadar);
    notifyListeners();

    final http = HttpClient()..connectionTimeout = const Duration(seconds: 90);
    try {
      for (final bucket in rankingBuckets) {
        if (!force && _cache.isFreshSync(bucket.top)) {
          listUpdateDone++;
          notifyListeners();
          continue;
        }
        statusMessage = l10n.listUpdating(bucket.label);
        notifyListeners();
        try {
          await _cache.refresh(
            bucket,
            source: radarSource,
            baseUrl: efhServerBaseUrl,
            token: cfToken.trim(),
            client: http,
          );
        } catch (_) {
          // Keep whatever cache already exists for this bucket.
        }
        listUpdateDone++;
        notifyListeners();
      }
      await _rebuildHeat();
      listsUpdatedAt = DateTime.now();
    } finally {
      // Keep the loading bar visible for at least a moment so the startup
      // check is perceptible even when every list is already fresh.
      const minimum = Duration(milliseconds: 1500);
      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < minimum) {
        await Future<void>.delayed(minimum - elapsed);
      }
      http.close(force: true);
      warmingUp = false;
      statusMessage = null;
      notifyListeners();
    }
  }

  Future<void> _rebuildHeat() async {
    final map = <String, int>{};
    for (final bucket in rankingBuckets) {
      final domains = await _cache.read(bucket.top);
      if (domains == null) {
        continue;
      }
      for (final host in domains) {
        map.putIfAbsent(host, () => bucket.top);
      }
      if (map.length > _maxHeatEntries) {
        break;
      }
    }
    if (map.isNotEmpty) {
      _minTop = map;
    }
  }

  DateTime? lastUpdatedFor(int top) => _cache.lastUpdatedSync(top);

  // ---------------------------------------------------------------- 运行
  Future<void> start() async {
    if (running) {
      return;
    }
    final problem = _validate();
    if (problem != null) {
      error = problem;
      notifyListeners();
      return;
    }

    final workers = int.parse(workersText.trim());
    final timeoutSeconds = int.parse(timeoutText.trim());
    final token = CancelToken();
    final pause = PauseToken();
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 90);

    running = true;
    cancelled = false;
    error = null;
    stats = null;
    pending.clear();
    completed.clear();
    _pendingBySeq.clear();
    _startedSeqs.clear();
    done = 0;
    total = 0;
    startedAt = DateTime.now();
    _lastProgressAt = null;
    statusMessage = null;
    _cancelToken = token;
    _pauseToken = pause;
    _httpClient = http;
    notifyListeners();

    try {
      final String csv;
      if (source == DataSource.radar) {
        final selected = findBucket(selectedTop) ?? rankingBuckets.last;
        final domains = await _cache.load(
          selected,
          source: radarSource,
          baseUrl: efhServerBaseUrl,
          token: cfToken.trim(),
          client: http,
          cancelToken: token,
        );
        if (token.isCancelled) {
          return;
        }
        csv = writeDomainCsv(domains);
      } else {
        csv = await File(inputPath).readAsString();
      }
      // Know the total immediately so the progress bar moves right away.
      total = countRecords(csv);
      notifyListeners();
      await _runProbeIsolate(
        csv: csv,
        workers: workers,
        timeoutSeconds: timeoutSeconds,
      );
    } catch (exception) {
      if (!token.isCancelled) {
        error = exception.toString();
      }
    } finally {
      http.close(force: true);
      running = false;
      statusMessage = null;
      pending.clear();
      _pendingBySeq.clear();
      _cancelToken = null;
      _pauseToken = null;
      _isolateControl = null;
      _httpClient = null;
      _requestResultsRefresh(immediate: true);
      notifyListeners();
    }
  }

  /// Sends a control message to the probe isolate, queueing it until the
  /// control port is ready.
  void _sendControl(Map<String, Object?> message) {
    final port = _isolateControl;
    if (port != null) {
      port.send(message);
    } else {
      _pendingControl.add(message);
    }
  }

  /// Runs the probes in a background isolate so the UI thread never blocks.
  Future<void> _runProbeIsolate({
    required String csv,
    required int workers,
    required int timeoutSeconds,
  }) async {
    final port = ReceivePort();
    final done = Completer<void>();
    _isolateControl = null;
    _pendingControl.clear();

    port.listen((message) {
      if (message is! Map) {
        return;
      }
      switch (message['type']) {
        case 'control':
          _isolateControl = message['port'] as SendPort;
          for (final pending in _pendingControl) {
            _isolateControl!.send(pending);
          }
          _pendingControl.clear();
        case 'batch':
          for (final start in message['starts'] as List) {
            _applyStartMap((start as Map).cast<String, Object?>());
          }
          for (final result in message['results'] as List) {
            _applyResultMap((result as Map).cast<String, Object?>());
          }
          // One schedule for the whole batch instead of one per entry.
          _scheduleNotify();
          _requestResultsRefresh();
        case 'stats':
          _applyStatsMap(message.cast<String, Object?>());
        case 'revert':
          for (final seq in message['seqs'] as List) {
            _onRevert(seq as int);
          }
          _scheduleNotify();
          _requestResultsRefresh();
        case 'done':
          _applyStatsMap(message.cast<String, Object?>());
          if (!done.isCompleted) {
            done.complete();
          }
        case 'error':
          error = message['message'] as String?;
          if (!done.isCompleted) {
            done.complete();
          }
      }
    });

    final isolate = await Isolate.spawn(probeWorkerEntry, <Object?>[
      {
        'csv': csv,
        'workers': workers,
        'timeout': timeoutSeconds,
        'detectFortinet': hdsbDetection,
        'quickCheck': hdsbDetection && hdsbQuickCheck,
      },
      port.sendPort,
    ]);
    try {
      await done.future;
    } finally {
      isolate.kill(priority: Isolate.immediate);
      port.close();
    }
  }

  void _applyStartMap(Map<String, Object?> start) {
    final seq = start['seq'] as int;
    final host = start['host'] as String;
    final item = ResultItem.pending(seq: seq, host: host, top: heatFor(host));
    pending.add(item);
    _pendingBySeq[seq] = item;
    _startedSeqs.add(seq);
  }

  void _applyResultMap(Map<String, Object?> result) {
    final seq = result['seq'] as int;
    final item = _pendingBySeq.remove(seq);
    if (item == null) {
      return;
    }
    item.status = statusFromWire(result['status'] as String);
    item.detail = (result['detail'] as String?) ?? '';
    item.certificateError = (result['certificateError'] as String?) ?? '';
    pending.remove(item);
    completed.add(item);
    if (completed.length > maxResults) {
      completed.removeRange(0, completed.length - maxResults);
    }
  }

  void _applyStatsMap(Map<String, Object?> message) {
    stats = Stats(
      total: (message['total'] as int?) ?? 0,
      processed: (message['processed'] as int?) ?? 0,
      fortinetBlocked: (message['fortinet'] as int?) ?? 0,
      notFortinet: (message['notFortinet'] as int?) ?? 0,
      certificateError: (message['cert'] as int?) ?? 0,
      failed: (message['failed'] as int?) ?? 0,
    );
    done = stats!.processed;
    total = stats!.total;
    _scheduleNotify();
  }

  /// Cancels the whole run.
  void stop() {
    if (!running) {
      return;
    }
    cancelled = true;
    _sendControl({'type': 'cancel'});
    _pauseToken?.resume();
    _cancelToken?.cancel();
    _httpClient?.close(force: true);
    pending.clear();
    _pendingBySeq.clear();
    _requestResultsRefresh(immediate: true);
    notifyListeners();
  }

  /// Stops launching new probes; in-flight probes are interrupted.
  void pause() {
    if (!running || paused) {
      return;
    }
    _sendControl({'type': 'pause'});
    _pauseToken?.pause();
    _requestResultsRefresh(immediate: true);
    notifyListeners();
  }

  /// Resumes launching probes after [pause].
  void resume() {
    if (!running) {
      return;
    }
    _sendControl({'type': 'resume'});
    _pauseToken?.resume();
    _requestResultsRefresh(immediate: true);
    notifyListeners();
  }

  /// Called when a probe was interrupted by a pause; the domain goes back to
  /// the waiting list until the run resumes.
  void _onRevert(int seq) {
    final item = _pendingBySeq.remove(seq);
    if (item != null) {
      pending.remove(item);
    }
  }

  String? _validate() {
    final workers = int.tryParse(workersText.trim());
    final timeoutSeconds = int.tryParse(timeoutText.trim());
    if (workers == null || workers <= 0) {
      return l10n.validationWorkers;
    }
    if (timeoutSeconds == null || timeoutSeconds <= 0) {
      return l10n.validationTimeout;
    }
    if (source == DataSource.local && inputPath.trim().isEmpty) {
      return l10n.validationInputFile;
    }
    return null;
  }

  // ---------------------------------------------------------------- Reporter
  @override
  void progress(int doneCount, int totalCount) {
    done = doneCount;
    total = totalCount;
    final now = DateTime.now();
    final last = _lastProgressAt;
    if (last != null &&
        now.difference(last) < const Duration(milliseconds: 200) &&
        doneCount != totalCount) {
      return;
    }
    _lastProgressAt = now;
    notifyListeners();
  }

  @override
  void alert(CheckResult result) {}

  @override
  void message(String text) {}

  void _scheduleNotify() {
    _notifyTimer ??= Timer(const Duration(milliseconds: 300), () {
      _notifyTimer = null;
      notifyListeners();
    });
  }

  void _requestResultsRefresh({bool immediate = false}) {
    if (immediate) {
      _revisionTimer?.cancel();
      _revisionTimer = null;
      _revisionDirty = false;
      resultsRevision.value++;
      return;
    }
    _revisionDirty = true;
    _revisionTimer ??= Timer(const Duration(milliseconds: 400), () {
      _revisionTimer = null;
      if (_revisionDirty) {
        _revisionDirty = false;
        resultsRevision.value++;
      }
    });
  }

  @override
  void dispose() {
    _notifyTimer?.cancel();
    _saveTimer?.cancel();
    _revisionTimer?.cancel();
    resultsRevision.dispose();
    _httpClient?.close(force: true);
    super.dispose();
  }
}
