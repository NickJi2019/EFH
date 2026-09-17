// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '网站屏蔽检测';

  @override
  String get navDashboard => '检测';

  @override
  String get navLogs => '日志';

  @override
  String get navSettings => '设置';

  @override
  String get navAbout => '关于';

  @override
  String get actionStart => '开始';

  @override
  String get actionStop => '停止';

  @override
  String get actionPause => '暂停';

  @override
  String get actionResume => '恢复';

  @override
  String get actionCancel => '取消';

  @override
  String get actionClear => '清空';

  @override
  String get actionExportJson => '导出结果 JSON';

  @override
  String get actionAutoScrollStop => '停止自动滚动';

  @override
  String get actionAutoScrollStart => '自动滚动到底部';

  @override
  String get actionChooseFile => '选择文件';

  @override
  String get stateRunning => '检测中';

  @override
  String get statePaused => '已暂停';

  @override
  String get stateCancelled => '已取消';

  @override
  String get statePreparing => '准备中';

  @override
  String get stateError => '出错';

  @override
  String get stateDone => '已完成';

  @override
  String get stateIdle => '未开始';

  @override
  String ratePerSecond(String rate) {
    return '$rate 域名/秒';
  }

  @override
  String progressCounter(int done, int total, String percent) {
    return '$done / $total（$percent%）';
  }

  @override
  String progressBreakdown(int reachable, int blocked) {
    return '可达 $reachable · 被屏蔽 $blocked';
  }

  @override
  String get sourceTitle => '数据来源';

  @override
  String get sourceRadar => 'Cloudflare Radar';

  @override
  String get sourceLocal => '本地 CSV';

  @override
  String get listSource => '列表来源';

  @override
  String get efhServer => 'EFHServer';

  @override
  String get cloudflareDirect => 'Cloudflare 直连';

  @override
  String get serverUrlLabel => 'EFHServer 地址';

  @override
  String get cloudflareTokenHint =>
      '直连 Cloudflare 使用“设置”页中的 CF Token；留空则读取环境变量 CF_Token。';

  @override
  String get listToCheck => '要检查的列表';

  @override
  String get logListLabel => '实时日志依据的列表';

  @override
  String get noFileSelected => '未选择文件';

  @override
  String get paramsTitle => '参数';

  @override
  String get workersLabel => '并发数';

  @override
  String get timeoutLabel => '单站超时（秒）';

  @override
  String get hdsbDetectionLabel => '针对 HDSB 防火墙检测';

  @override
  String get hdsbDetectionDesc =>
      '针对性检测 HDSB 防火墙的提供商 Fortinet 所签发的证书；如果正常的网站证书被替换为 Fortinet 证书，则说明该网站被屏蔽。';

  @override
  String get hdsbQuickCheckLabel => '针对 HDSB 的快速检查';

  @override
  String get hdsbQuickCheckDesc => '仅检查证书签发者，而不检查实际服务器情况。';

  @override
  String get badgeOtherProblem => '其他问题';

  @override
  String get badgeReachable => '可以访问';

  @override
  String get badgeBlocked => '被屏蔽';

  @override
  String get badgeHdsbBlocked => '明确被 HDSB 屏蔽';

  @override
  String get badgeDnsError => 'DNS 错误';

  @override
  String get badgeUnreachable => '无法访问';

  @override
  String get badgeCertificateExpired => '证书过期';

  @override
  String get explanationReachable => '该网站的 HTTP 页面可以被正常访问。';

  @override
  String get explanationDns => '该网站的域名无法被解析，可能是因为该网站未在此域名提供服务，或DNS被劫持。';

  @override
  String get explanationTimeout => '该网站服务器未响应，可能是网站出现错误、网站被屏蔽或网络环境问题。';

  @override
  String get explanationCertificate => '该网站使用了过期/错误/未被信任的证书，也可能是被屏蔽。';

  @override
  String get explanationUnreachable => '该网站无法访问，可能是服务器错误或网络环境问题。';

  @override
  String get explanationBlocked => '该网站明确被 HDSB 的 Fortinet 防火墙屏蔽。';

  @override
  String get statsTitle => '结果统计';

  @override
  String get statTotal => '总数';

  @override
  String get statProcessed => '已处理';

  @override
  String get statHdsb => 'HDSB 屏蔽';

  @override
  String get statCertError => '证书错误';

  @override
  String get statFailed => '其他失败';

  @override
  String logsTitle(int count) {
    return '日志（$count）';
  }

  @override
  String get logsEmpty => '暂无日志';

  @override
  String get settingsCloudflare => 'Cloudflare';

  @override
  String get cfTokenLabel => 'CF Token';

  @override
  String get cfTokenHint => 'Cloudflare Radar 数据集读取令牌';

  @override
  String get cfTokenHelp =>
      '使用“Cloudflare 直连”来源时用于回退到 Radar 数据集 API；使用 EFHServer 来源时无需填写。';

  @override
  String get languageTitle => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get aboutTitle => '网站屏蔽检测';

  @override
  String get updateTitle => '检查更新';

  @override
  String get updateCurrentVersion => '当前版本';

  @override
  String get updateChecking => '正在检查更新…';

  @override
  String get updateUpToDate => '已是最新版本';

  @override
  String get updateAvailable => '发现新版本';

  @override
  String get updateDownload => '前往下载';

  @override
  String get updateCheckFailed => '检查更新失败';

  @override
  String get updateNotChecked => '尚未检查';

  @override
  String get actionCheckUpdate => '检查更新';

  @override
  String get aboutSubtitle => '批量探测域名证书、识别屏蔽情况并导出 JSON。';

  @override
  String get aboutPrinciples => '工作原理';

  @override
  String get principleMethodTitle => '检测方式';

  @override
  String get principleMethodDesc => '对每个域名做 TLS 握手（端口 443，SNI），读取叶证书的签发者。';

  @override
  String get principleCriteriaTitle => '判定依据';

  @override
  String get principleCriteriaDesc => '仅在启用 HDSB 检测且证书签发者匹配时标记为被屏蔽。这是指示而非结论。';

  @override
  String get principleTrustTitle => '证书信任';

  @override
  String get principleTrustDesc => '握手刻意接受不受信任的证书，以便检查中间人拦截证书。';

  @override
  String get principleSourceTitle => '数据来源';

  @override
  String get principleSourceDesc =>
      'Cloudflare Radar Top-N 列表，可经 EFHServer 代理或直连获取。';

  @override
  String get pickFileTitle => '选择域名列表 CSV';

  @override
  String get exportDialogTitle => '导出检测结果';

  @override
  String logInputRadar(String label) {
    return '输入：Cloudflare Radar $label';
  }

  @override
  String logSource(String source) {
    return '来源：$source';
  }

  @override
  String logMerged(int count) {
    return '已合并 $count 个域名';
  }

  @override
  String logInputPath(String path) {
    return '输入：$path';
  }

  @override
  String logError(String error) {
    return '错误：$error';
  }

  @override
  String get logCancelled => '已取消';

  @override
  String get logStopping => '正在停止…';

  @override
  String logFinished(int count) {
    return '完成，共处理 $count 个域名';
  }

  @override
  String get validationWorkers => '并发数必须为正整数';

  @override
  String get validationTimeout => '超时秒数必须为正整数';

  @override
  String get validationInputFile => '请先选择输入 CSV 文件';

  @override
  String get validationServerUrl => '请填写 EFHServer 地址';

  @override
  String get snackCancelledExport => '已取消导出';

  @override
  String snackExported(String path) {
    return '已导出：$path';
  }

  @override
  String snackExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String snackPickFailed(String error) {
    return '选择文件失败：$error';
  }

  @override
  String listUpdating(String label) {
    return '正在更新 $label…';
  }

  @override
  String get updateSettingsTitle => '更新设置';

  @override
  String get updateNow => '立即更新';

  @override
  String get updating => '更新中…';

  @override
  String lastUpdated(String time) {
    return '更新于 $time';
  }

  @override
  String get neverUpdated => '尚未更新';

  @override
  String get serverAddressLabel => '服务器地址';

  @override
  String get filterStatus => '状态';

  @override
  String get filterHeat => '热度';

  @override
  String get filterTitle => '筛选';

  @override
  String get searchHint => '搜索域名';

  @override
  String get filterAll => '全部';

  @override
  String get filterNotBlocked => '未被屏蔽';

  @override
  String get filterBlocked => '被屏蔽';

  @override
  String get filterError => '其他错误';

  @override
  String get resultsEmpty => '暂无结果';

  @override
  String get itemChecking => '检测中…';

  @override
  String get detailStatus => '状态';

  @override
  String get detailHeat => '热度';

  @override
  String get detailTitle => '标题';

  @override
  String get detailCertError => '证书详情';

  @override
  String get detailMessage => '错误详情';

  @override
  String get statusChecking => '检测中';

  @override
  String get statusBlocked => '被屏蔽';

  @override
  String get statusNotBlocked => '未被屏蔽';

  @override
  String get statusCertificateError => '证书错误';

  @override
  String get statusDnsError => 'DNS 错误';

  @override
  String get statusTimeout => '超时';

  @override
  String get statusConnectionRefused => '连接被拒绝';

  @override
  String get statusNetworkError => 'TLS/网络错误';

  @override
  String get statusInvalidInput => '无效输入';

  @override
  String get autoScrollOn => '自动滚动';

  @override
  String get autoScrollOff => '手动';

  @override
  String get themeTitle => '主题';

  @override
  String get themeColorLabel => '主题色';

  @override
  String get themeModeLabel => '模式';

  @override
  String get themeModeSystem => '跟随系统';

  @override
  String get themeModeLight => '浅色';

  @override
  String get themeModeDark => '深色';

  @override
  String get themeColorDefault => '默认';

  @override
  String get themeColorCustom => '自定义';

  @override
  String get themeFollowSystem => '跟随系统主题色';

  @override
  String get themeFollowSystemDark => '跟随系统明暗模式';

  @override
  String get themeDarkMode => '深色模式';

  @override
  String get dialogOk => '确定';
}
