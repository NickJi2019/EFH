import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Website Blocking Detection'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get navDashboard;

  /// No description provided for @navLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get navLogs;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get navAbout;

  /// No description provided for @actionStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get actionStart;

  /// No description provided for @actionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get actionStop;

  /// No description provided for @actionPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get actionPause;

  /// No description provided for @actionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionExportJson.
  ///
  /// In en, this message translates to:
  /// **'Export results as JSON'**
  String get actionExportJson;

  /// No description provided for @actionAutoScrollStop.
  ///
  /// In en, this message translates to:
  /// **'Stop auto-scrolling'**
  String get actionAutoScrollStop;

  /// No description provided for @actionAutoScrollStart.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll to bottom'**
  String get actionAutoScrollStart;

  /// No description provided for @actionChooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose file'**
  String get actionChooseFile;

  /// No description provided for @stateRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get stateRunning;

  /// No description provided for @statePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get statePaused;

  /// No description provided for @stateCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get stateCancelled;

  /// No description provided for @statePreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get statePreparing;

  /// No description provided for @stateError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get stateError;

  /// No description provided for @stateDone.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get stateDone;

  /// No description provided for @stateIdle.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get stateIdle;

  /// No description provided for @ratePerSecond.
  ///
  /// In en, this message translates to:
  /// **'{rate} domains/s'**
  String ratePerSecond(String rate);

  /// No description provided for @progressCounter.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} ({percent}%)'**
  String progressCounter(int done, int total, String percent);

  /// No description provided for @progressBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Reachable {reachable} · Blocked {blocked}'**
  String progressBreakdown(int reachable, int blocked);

  /// No description provided for @sourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get sourceTitle;

  /// No description provided for @sourceRadar.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare Radar'**
  String get sourceRadar;

  /// No description provided for @sourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local CSV'**
  String get sourceLocal;

  /// No description provided for @listSource.
  ///
  /// In en, this message translates to:
  /// **'List source'**
  String get listSource;

  /// No description provided for @efhServer.
  ///
  /// In en, this message translates to:
  /// **'EFHServer'**
  String get efhServer;

  /// No description provided for @cloudflareDirect.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare direct'**
  String get cloudflareDirect;

  /// No description provided for @serverUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'EFHServer URL'**
  String get serverUrlLabel;

  /// No description provided for @cloudflareTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare direct uses the CF Token from Settings; leave it empty to read the CF_Token environment variable.'**
  String get cloudflareTokenHint;

  /// No description provided for @listToCheck.
  ///
  /// In en, this message translates to:
  /// **'List to check'**
  String get listToCheck;

  /// No description provided for @logListLabel.
  ///
  /// In en, this message translates to:
  /// **'List used for the live log'**
  String get logListLabel;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @paramsTitle.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get paramsTitle;

  /// No description provided for @workersLabel.
  ///
  /// In en, this message translates to:
  /// **'Concurrency'**
  String get workersLabel;

  /// No description provided for @timeoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Per-host timeout (s)'**
  String get timeoutLabel;

  /// No description provided for @hdsbDetectionLabel.
  ///
  /// In en, this message translates to:
  /// **'HDSB firewall detection'**
  String get hdsbDetectionLabel;

  /// No description provided for @hdsbDetectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Detects certificates issued by Fortinet, the vendor of the HDSB firewall. If a normal site\'s certificate is replaced by a Fortinet certificate, the site is considered blocked.'**
  String get hdsbDetectionDesc;

  /// No description provided for @hdsbQuickCheckLabel.
  ///
  /// In en, this message translates to:
  /// **'HDSB quick check'**
  String get hdsbQuickCheckLabel;

  /// No description provided for @hdsbQuickCheckDesc.
  ///
  /// In en, this message translates to:
  /// **'Only checks the certificate issuer, not the actual server state.'**
  String get hdsbQuickCheckDesc;

  /// No description provided for @badgeOtherProblem.
  ///
  /// In en, this message translates to:
  /// **'Other issue'**
  String get badgeOtherProblem;

  /// No description provided for @badgeReachable.
  ///
  /// In en, this message translates to:
  /// **'Accessible'**
  String get badgeReachable;

  /// No description provided for @badgeBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get badgeBlocked;

  /// No description provided for @badgeHdsbBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked by HDSB'**
  String get badgeHdsbBlocked;

  /// No description provided for @badgeDnsError.
  ///
  /// In en, this message translates to:
  /// **'DNS error'**
  String get badgeDnsError;

  /// No description provided for @badgeUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Unreachable'**
  String get badgeUnreachable;

  /// No description provided for @badgeCertificateExpired.
  ///
  /// In en, this message translates to:
  /// **'Certificate expired'**
  String get badgeCertificateExpired;

  /// No description provided for @explanationReachable.
  ///
  /// In en, this message translates to:
  /// **'The site\'s HTTP page can be opened normally.'**
  String get explanationReachable;

  /// No description provided for @explanationDns.
  ///
  /// In en, this message translates to:
  /// **'The domain cannot be resolved; the site may not serve anything at this domain, or DNS may be hijacked.'**
  String get explanationDns;

  /// No description provided for @explanationTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server did not respond; the site may be broken, blocked, or the network may be at fault.'**
  String get explanationTimeout;

  /// No description provided for @explanationCertificate.
  ///
  /// In en, this message translates to:
  /// **'The site uses an expired, wrong, or untrusted certificate; it may also be blocked.'**
  String get explanationCertificate;

  /// No description provided for @explanationUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The site cannot be reached; the server may be down or the network may be at fault.'**
  String get explanationUnreachable;

  /// No description provided for @explanationBlocked.
  ///
  /// In en, this message translates to:
  /// **'This site is explicitly blocked by the HDSB Fortinet firewall.'**
  String get explanationBlocked;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Result statistics'**
  String get statsTitle;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @statProcessed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get statProcessed;

  /// No description provided for @statHdsb.
  ///
  /// In en, this message translates to:
  /// **'HDSB blocked'**
  String get statHdsb;

  /// No description provided for @statCertError.
  ///
  /// In en, this message translates to:
  /// **'Certificate errors'**
  String get statCertError;

  /// No description provided for @statFailed.
  ///
  /// In en, this message translates to:
  /// **'Other failures'**
  String get statFailed;

  /// No description provided for @logsTitle.
  ///
  /// In en, this message translates to:
  /// **'Logs ({count})'**
  String logsTitle(int count);

  /// No description provided for @logsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get logsEmpty;

  /// No description provided for @settingsCloudflare.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare'**
  String get settingsCloudflare;

  /// No description provided for @cfTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'CF Token'**
  String get cfTokenLabel;

  /// No description provided for @cfTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare Radar dataset read token'**
  String get cfTokenHint;

  /// No description provided for @cfTokenHelp.
  ///
  /// In en, this message translates to:
  /// **'Used to fall back to the Radar dataset API when using the Cloudflare direct source. Not needed for the EFHServer source.'**
  String get cfTokenHelp;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'Website Blocking Detection'**
  String get aboutTitle;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateTitle;

  /// No description provided for @updateCurrentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get updateCurrentVersion;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the latest version'**
  String get updateUpToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'New version available'**
  String get updateAvailable;

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get updateDownload;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check failed'**
  String get updateCheckFailed;

  /// No description provided for @updateNotChecked.
  ///
  /// In en, this message translates to:
  /// **'Not checked yet'**
  String get updateNotChecked;

  /// No description provided for @actionCheckUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get actionCheckUpdate;

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Probe domain certificates in bulk, detect blocked sites and export JSON.'**
  String get aboutSubtitle;

  /// No description provided for @aboutPrinciples.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get aboutPrinciples;

  /// No description provided for @principleMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get principleMethodTitle;

  /// No description provided for @principleMethodDesc.
  ///
  /// In en, this message translates to:
  /// **'Performs a TLS handshake (port 443, SNI) for each domain and reads the leaf certificate issuer.'**
  String get principleMethodDesc;

  /// No description provided for @principleCriteriaTitle.
  ///
  /// In en, this message translates to:
  /// **'Criteria'**
  String get principleCriteriaTitle;

  /// No description provided for @principleCriteriaDesc.
  ///
  /// In en, this message translates to:
  /// **'Marks the result blocked only when HDSB detection is enabled and the certificate issuer matches. It is an indicator, not a conclusion.'**
  String get principleCriteriaDesc;

  /// No description provided for @principleTrustTitle.
  ///
  /// In en, this message translates to:
  /// **'Certificate trust'**
  String get principleTrustTitle;

  /// No description provided for @principleTrustDesc.
  ///
  /// In en, this message translates to:
  /// **'The handshake deliberately accepts untrusted certificates so interception certificates can be inspected.'**
  String get principleTrustDesc;

  /// No description provided for @principleSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Data source'**
  String get principleSourceTitle;

  /// No description provided for @principleSourceDesc.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare Radar Top-N lists, fetched through EFHServer or directly.'**
  String get principleSourceDesc;

  /// No description provided for @pickFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a domain list CSV'**
  String get pickFileTitle;

  /// No description provided for @exportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export results'**
  String get exportDialogTitle;

  /// No description provided for @logInputRadar.
  ///
  /// In en, this message translates to:
  /// **'Input: Cloudflare Radar {label}'**
  String logInputRadar(String label);

  /// No description provided for @logSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String logSource(String source);

  /// No description provided for @logMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged {count} domains'**
  String logMerged(int count);

  /// No description provided for @logInputPath.
  ///
  /// In en, this message translates to:
  /// **'Input: {path}'**
  String logInputPath(String path);

  /// No description provided for @logError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String logError(String error);

  /// No description provided for @logCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get logCancelled;

  /// No description provided for @logStopping.
  ///
  /// In en, this message translates to:
  /// **'Stopping…'**
  String get logStopping;

  /// No description provided for @logFinished.
  ///
  /// In en, this message translates to:
  /// **'Done, processed {count} domains'**
  String logFinished(int count);

  /// No description provided for @validationWorkers.
  ///
  /// In en, this message translates to:
  /// **'Concurrency must be a positive integer'**
  String get validationWorkers;

  /// No description provided for @validationTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout must be a positive integer'**
  String get validationTimeout;

  /// No description provided for @validationInputFile.
  ///
  /// In en, this message translates to:
  /// **'Please choose an input CSV file first'**
  String get validationInputFile;

  /// No description provided for @validationServerUrl.
  ///
  /// In en, this message translates to:
  /// **'Please fill in the EFHServer URL'**
  String get validationServerUrl;

  /// No description provided for @snackCancelledExport.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled'**
  String get snackCancelledExport;

  /// No description provided for @snackExported.
  ///
  /// In en, this message translates to:
  /// **'Exported: {path}'**
  String snackExported(String path);

  /// No description provided for @snackExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String snackExportFailed(String error);

  /// No description provided for @snackPickFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to choose file: {error}'**
  String snackPickFailed(String error);

  /// No description provided for @listUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating {label}…'**
  String listUpdating(String label);

  /// No description provided for @updateSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Update settings'**
  String get updateSettingsTitle;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String lastUpdated(String time);

  /// No description provided for @neverUpdated.
  ///
  /// In en, this message translates to:
  /// **'Never updated'**
  String get neverUpdated;

  /// No description provided for @serverAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddressLabel;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// No description provided for @filterHeat.
  ///
  /// In en, this message translates to:
  /// **'Heat'**
  String get filterHeat;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search domain'**
  String get searchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterNotBlocked.
  ///
  /// In en, this message translates to:
  /// **'Not blocked'**
  String get filterNotBlocked;

  /// No description provided for @filterBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get filterBlocked;

  /// No description provided for @filterError.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get filterError;

  /// No description provided for @resultsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results yet'**
  String get resultsEmpty;

  /// No description provided for @itemChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get itemChecking;

  /// No description provided for @detailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detailStatus;

  /// No description provided for @detailHeat.
  ///
  /// In en, this message translates to:
  /// **'Heat'**
  String get detailHeat;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get detailTitle;

  /// No description provided for @detailCertError.
  ///
  /// In en, this message translates to:
  /// **'Certificate detail'**
  String get detailCertError;

  /// No description provided for @detailMessage.
  ///
  /// In en, this message translates to:
  /// **'Error detail'**
  String get detailMessage;

  /// No description provided for @statusChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get statusChecking;

  /// No description provided for @statusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// No description provided for @statusNotBlocked.
  ///
  /// In en, this message translates to:
  /// **'Not blocked'**
  String get statusNotBlocked;

  /// No description provided for @statusCertificateError.
  ///
  /// In en, this message translates to:
  /// **'Certificate error'**
  String get statusCertificateError;

  /// No description provided for @statusDnsError.
  ///
  /// In en, this message translates to:
  /// **'DNS error'**
  String get statusDnsError;

  /// No description provided for @statusTimeout.
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get statusTimeout;

  /// No description provided for @statusConnectionRefused.
  ///
  /// In en, this message translates to:
  /// **'Connection refused'**
  String get statusConnectionRefused;

  /// No description provided for @statusNetworkError.
  ///
  /// In en, this message translates to:
  /// **'TLS/network error'**
  String get statusNetworkError;

  /// No description provided for @statusInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get statusInvalidInput;

  /// No description provided for @autoScrollOn.
  ///
  /// In en, this message translates to:
  /// **'Auto-scroll'**
  String get autoScrollOn;

  /// No description provided for @autoScrollOff.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get autoScrollOff;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeTitle;

  /// No description provided for @themeColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get themeColorLabel;

  /// No description provided for @themeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get themeModeLabel;

  /// No description provided for @themeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeModeDark;

  /// No description provided for @themeColorDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get themeColorDefault;

  /// No description provided for @themeColorCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get themeColorCustom;

  /// No description provided for @themeFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow system accent color'**
  String get themeFollowSystem;

  /// No description provided for @themeFollowSystemDark.
  ///
  /// In en, this message translates to:
  /// **'Follow system dark mode'**
  String get themeFollowSystemDark;

  /// No description provided for @themeDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get themeDarkMode;

  /// No description provided for @dialogOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dialogOk;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
