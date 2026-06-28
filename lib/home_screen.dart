import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'webview_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final SharedPreferences prefs;

  const HomeScreen({super.key, required this.prefs});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _currentUrl;
  late bool _keyboardEnabled;

  // Triple-tap detection untuk buka settings
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _currentUrl = widget.prefs.getString('app_url') ?? 'https://google.com';
      _keyboardEnabled = widget.prefs.getBool('keyboard_enabled') ?? true;
    });
  }

  /// Handle triple-tap pada area logo/title untuk buka settings
  void _handleTitleTap() {
    final now = DateTime.now();

    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 800) {
      _tapCount++;
    } else {
      _tapCount = 1;
    }

    _lastTapTime = now;

    if (_tapCount >= 3) {
      _tapCount = 0;
      _openSettings();
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initialUrl: _currentUrl,
          initialKeyboardEnabled: _keyboardEnabled,
          prefs: widget.prefs,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _currentUrl = result['url'] as String;
        _keyboardEnabled = result['keyboard_enabled'] as bool;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // WebView utama — full screen
          WebViewScreen(
            url: _currentUrl,
            keyboardEnabled: _keyboardEnabled,
          ),

          // Invisible triple-tap area di pojok kiri atas untuk buka settings
          Positioned(
            top: 0,
            left: 0,
            child: GestureDetector(
              onTap: _handleTitleTap,
              child: Container(
                width: 60,
                height: 60,
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
