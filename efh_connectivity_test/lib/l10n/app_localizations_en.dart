// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Website Blocking Detection';

  @override
  String get navDashboard => 'Check';

  @override
  String get navLogs => 'Logs';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAbout => 'About';

  @override
  String get actionStart => 'Start';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionExportJson => 'Export results as JSON';

  @override
  String get actionAutoScrollStop => 'Stop auto-scrolling';

  @override
  String get actionAutoScrollStart => 'Auto-scroll to bottom';

  @override
  String get actionChooseFile => 'Choose file';

  @override
  String get stateRunning => 'Running';

  @override
  String get statePaused => 'Paused';

  @override
  String get stateCancelled => 'Cancelled';

  @override
  String get statePreparing => 'Preparing';

  @override
  String get stateError => 'Error';

  @override
  String get stateDone => 'Finished';

  @override
  String get stateIdle => 'Not started';

  @override
  String ratePerSecond(String rate) {
    return '$rate domains/s';
  }

  @override
  String progressCounter(int done, int total, String percent) {
    return '$done / $total ($percent%)';
  }

  @override
  String progressBreakdown(int reachable, int blocked) {
    return 'Reachable $reachable · Blocked $blocked';
  }

  @override
  String get sourceTitle => 'Data source';

  @override
  String get sourceRadar => 'Cloudflare Radar';

  @override
  String get sourceLocal => 'Local CSV';

  @override
  String get listSource => 'List source';

  @override
  String get efhServer => 'EFHServer';

  @override
  String get cloudflareDirect => 'Cloudflare direct';

  @override
  String get serverUrlLabel => 'EFHServer URL';

  @override
  String get cloudflareTokenHint =>
      'Cloudflare direct uses the CF Token from Settings; leave it empty to read the CF_Token environment variable.';

  @override
  String get listToCheck => 'List to check';

  @override
  String get logListLabel => 'List used for the live log';

  @override
  String get noFileSelected => 'No file selected';

  @override
  String get paramsTitle => 'Parameters';

  @override
  String get workersLabel => 'Concurrency';

  @override
  String get timeoutLabel => 'Per-host timeout (s)';

  @override
  String get hdsbDetectionLabel => 'HDSB firewall detection';

  @override
  String get hdsbDetectionDesc =>
      'Detects certificates issued by Fortinet, the vendor of the HDSB firewall. If a normal site\'s certificate is replaced by a Fortinet certificate, the site is considered blocked.';

  @override
  String get hdsbQuickCheckLabel => 'HDSB quick check';

  @override
  String get hdsbQuickCheckDesc =>
      'Only checks the certificate issuer, not the actual server state.';

  @override
  String get badgeOtherProblem => 'Other issue';

  @override
  String get badgeCertUnavailable => 'Certificate unavailable';

  @override
  String get badgeReachable => 'Accessible';

  @override
  String get badgeBlocked => 'Blocked';

  @override
  String get badgeHdsbBlocked => 'Blocked by HDSB';

  @override
  String get badgeDnsError => 'DNS error';

  @override
  String get badgeUnreachable => 'Unreachable';

  @override
  String get badgeCertificateExpired => 'Certificate expired';

  @override
  String get explanationReachable =>
      'The site\'s HTTP page can be opened normally.';

  @override
  String get explanationDns =>
      'The domain cannot be resolved; the site may not serve anything at this domain, or DNS may be hijacked.';

  @override
  String get explanationTimeout =>
      'The server did not respond; the site may be broken, blocked, or the network may be at fault.';

  @override
  String get explanationCertificate =>
      'The site uses an expired, wrong, or untrusted certificate; it may also be blocked.';

  @override
  String get explanationUnreachable =>
      'The site cannot be reached; the server may be down or the network may be at fault.';

  @override
  String get explanationBlocked =>
      'This site is explicitly blocked by the HDSB Fortinet firewall.';

  @override
  String get statsTitle => 'Result statistics';

  @override
  String get statTotal => 'Total';

  @override
  String get statProcessed => 'Processed';

  @override
  String get statHdsb => 'HDSB blocked';

  @override
  String get statCertError => 'Certificate errors';

  @override
  String get statFailed => 'Other failures';

  @override
  String logsTitle(int count) {
    return 'Logs ($count)';
  }

  @override
  String get logsEmpty => 'No logs yet';

  @override
  String get settingsCloudflare => 'Cloudflare';

  @override
  String get cfTokenLabel => 'CF Token';

  @override
  String get cfTokenHint => 'Cloudflare Radar dataset read token';

  @override
  String get cfTokenHelp =>
      'Used to fall back to the Radar dataset API when using the Cloudflare direct source. Not needed for the EFHServer source.';

  @override
  String get dnsTitle => 'DNS resolution';

  @override
  String get dnsSystem => 'System DNS';

  @override
  String get dnsSystemDesc =>
      'Use the operating system resolver (most compatible)';

  @override
  String get dnsCloudflare => 'Cloudflare DoH';

  @override
  String get dnsCloudflareDesc =>
      'Resolve over encrypted DNS to avoid poisoning (default)';

  @override
  String get dnsCustom => 'Custom DoH';

  @override
  String get dnsCustomDesc => 'Use your own DoH endpoint';

  @override
  String get dnsCustomUrlLabel => 'DoH URL';

  @override
  String get dnsCustomUrlHint => 'https://example.com/dns-query';

  @override
  String get validationDohUrl => 'Enter a valid http(s) DoH URL';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get aboutTitle => 'Website Blocking Detection';

  @override
  String get updateTitle => 'Check for updates';

  @override
  String get updateCurrentVersion => 'Current version';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateUpToDate => 'You\'re on the latest version';

  @override
  String get updateAvailable => 'New version available';

  @override
  String get updateDownload => 'Download';

  @override
  String get updateCheckFailed => 'Update check failed';

  @override
  String get updateNotChecked => 'Not checked yet';

  @override
  String get actionCheckUpdate => 'Check';

  @override
  String get aboutSubtitle =>
      'Probe domain certificates in bulk, detect blocked sites and export JSON.';

  @override
  String get aboutPrinciples => 'How it works';

  @override
  String get principleMethodTitle => 'Method';

  @override
  String get principleMethodDesc =>
      'Performs a TLS handshake (port 443, SNI) for each domain and reads the leaf certificate issuer.';

  @override
  String get principleCriteriaTitle => 'Criteria';

  @override
  String get principleCriteriaDesc =>
      'Marks the result blocked only when HDSB detection is enabled and the certificate issuer matches. It is an indicator, not a conclusion.';

  @override
  String get principleTrustTitle => 'Certificate trust';

  @override
  String get principleTrustDesc =>
      'The handshake deliberately accepts untrusted certificates so interception certificates can be inspected.';

  @override
  String get principleSourceTitle => 'Data source';

  @override
  String get principleSourceDesc =>
      'Cloudflare Radar Top-N lists, fetched through EFHServer or directly.';

  @override
  String get pickFileTitle => 'Choose a domain list CSV';

  @override
  String get exportDialogTitle => 'Export results';

  @override
  String logInputRadar(String label) {
    return 'Input: Cloudflare Radar $label';
  }

  @override
  String logSource(String source) {
    return 'Source: $source';
  }

  @override
  String logMerged(int count) {
    return 'Merged $count domains';
  }

  @override
  String logInputPath(String path) {
    return 'Input: $path';
  }

  @override
  String logError(String error) {
    return 'Error: $error';
  }

  @override
  String get logCancelled => 'Cancelled';

  @override
  String get logStopping => 'Stopping…';

  @override
  String logFinished(int count) {
    return 'Done, processed $count domains';
  }

  @override
  String get validationWorkers => 'Concurrency must be a positive integer';

  @override
  String get validationTimeout => 'Timeout must be a positive integer';

  @override
  String get validationInputFile => 'Please choose an input CSV file first';

  @override
  String get validationServerUrl => 'Please fill in the EFHServer URL';

  @override
  String get snackCancelledExport => 'Export cancelled';

  @override
  String snackExported(String path) {
    return 'Exported: $path';
  }

  @override
  String snackExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String snackPickFailed(String error) {
    return 'Failed to choose file: $error';
  }

  @override
  String listUpdating(String label) {
    return 'Updating $label…';
  }

  @override
  String get updateSettingsTitle => 'Update settings';

  @override
  String get updateNow => 'Update now';

  @override
  String get updating => 'Updating…';

  @override
  String lastUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get neverUpdated => 'Never updated';

  @override
  String get serverAddressLabel => 'Server address';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterHeat => 'Heat';

  @override
  String get filterTitle => 'Filters';

  @override
  String get searchHint => 'Search domain';

  @override
  String get filterAll => 'All';

  @override
  String get filterNotBlocked => 'Not blocked';

  @override
  String get filterBlocked => 'Blocked';

  @override
  String get filterError => 'Errors';

  @override
  String get resultsEmpty => 'No results yet';

  @override
  String get itemChecking => 'Checking…';

  @override
  String get detailStatus => 'Status';

  @override
  String get detailHeat => 'Heat';

  @override
  String get detailTitle => 'Title';

  @override
  String get detailCertError => 'Certificate detail';

  @override
  String get detailMessage => 'Error detail';

  @override
  String get statusChecking => 'Checking';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get statusNotBlocked => 'Not blocked';

  @override
  String get statusCertificateError => 'Certificate error';

  @override
  String get statusDnsError => 'DNS error';

  @override
  String get statusTimeout => 'Timeout';

  @override
  String get statusConnectionRefused => 'Connection refused';

  @override
  String get statusNetworkError => 'TLS/network error';

  @override
  String get statusInvalidInput => 'Invalid input';

  @override
  String get autoScrollOn => 'Auto-scroll';

  @override
  String get autoScrollOff => 'Manual';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeColorLabel => 'Accent color';

  @override
  String get themeModeLabel => 'Mode';

  @override
  String get themeModeSystem => 'System';

  @override
  String get themeModeLight => 'Light';

  @override
  String get themeModeDark => 'Dark';

  @override
  String get themeColorDefault => 'Default';

  @override
  String get themeColorCustom => 'Custom';

  @override
  String get themeFollowSystem => 'Follow system accent color';

  @override
  String get themeFollowSystemDark => 'Follow system dark mode';

  @override
  String get themeDarkMode => 'Dark mode';

  @override
  String get dialogOk => 'OK';
}
