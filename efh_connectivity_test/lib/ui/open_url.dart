import 'dart:io';

import 'package:flutter/services.dart';

/// Hands a URL to the platform's browser on Android, where an app cannot spawn
/// a handler process itself. Implemented by `MainActivity`.
const MethodChannel _openUrlChannel = MethodChannel('efh/open_url');

/// Opens [url] with the platform's default handler.
///
/// Returns whether a handler could be launched. Kept dependency-free so the
/// app does not need a plugin just to open a release page.
Future<bool> openExternalUrl(String url) async {
  try {
    if (Platform.isAndroid) {
      final opened = await _openUrlChannel.invokeMethod<bool>('open', url);
      return opened ?? false;
    }
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
