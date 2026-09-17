import 'dart:convert';
import 'dart:io';

/// Reads and writes small user preferences as JSON at
/// `<home>/.efh_connectivity_test/settings.json`.
class SettingsStore {
  SettingsStore({Directory? directory})
    : file = File(
        '${(directory ?? Directory(_defaultDir())).path}/settings.json',
      );

  final File file;

  static String _defaultDir() {
    final home = Platform.environment['HOME'] ?? Directory.systemTemp.path;
    return '$home/.efh_connectivity_test';
  }

  Map<String, dynamic>? readSync() {
    try {
      if (!file.existsSync()) {
        return null;
      }
      final text = file.readAsStringSync().trim();
      if (text.isEmpty) {
        return null;
      }
      final data = jsonDecode(text);
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> data) async {
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      // Preferences are best-effort; ignore IO failures.
    }
  }
}
