import 'dart:convert';
import 'dart:io';

class AppConfig {
  String url;
  bool keyboardEnabled;

  AppConfig({
    this.url = 'https://google.com',
    this.keyboardEnabled = true,
  });

  static File get _file =>
      File('${File(Platform.resolvedExecutable).parent.path}/config.json');

  static Future<AppConfig> load() async {
    try {
      final f = _file;
      if (await f.exists()) {
        final data = jsonDecode(await f.readAsString());
        return AppConfig(
          url: data['url'] ?? 'https://google.com',
          keyboardEnabled: data['keyboard_enabled'] ?? true,
        );
      }
    } catch (_) {}
    return AppConfig();
  }

  Future<void> save() async {
    await _file.writeAsString(jsonEncode({
      'url': url,
      'keyboard_enabled': keyboardEnabled,
    }));
  }
}
