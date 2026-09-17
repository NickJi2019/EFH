import 'dart:io';

/// Opens [url] with the platform's default handler.
///
/// Returns whether a handler could be launched. Kept dependency-free so the
/// app does not need a plugin just to open a release page.
Future<bool> openExternalUrl(String url) async {
  try {
    if (Platform.isMacOS) {
      await Process.run('open', [url]);
      return true;
    }
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', url]);
      return true;
    }
    if (Platform.isLinux) {
      await Process.run('xdg-open', [url]);
      return true;
    }
  } catch (_) {
    // Fall through to false.
  }
  return false;
}
