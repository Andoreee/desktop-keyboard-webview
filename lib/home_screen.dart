import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_config.dart';
import 'webview_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppConfig config;

  const HomeScreen({super.key, required this.config});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _currentUrl;
  late bool _keyboardEnabled;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.config.url;
    _keyboardEnabled = widget.config.keyboardEnabled;
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          initialUrl: _currentUrl,
          initialKeyboardEnabled: _keyboardEnabled,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _currentUrl = result['url'] as String;
        _keyboardEnabled = result['keyboard_enabled'] as bool;
      });
      widget.config.url = _currentUrl;
      widget.config.keyboardEnabled = _keyboardEnabled;
      await widget.config.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyS):
            const _OpenSettingsIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyQ):
            const _QuitIntent(),
      },
      child: Actions(
        actions: {
          _OpenSettingsIntent: CallbackAction<_OpenSettingsIntent>(
            onInvoke: (_) => _openSettings(),
          ),
          _QuitIntent: CallbackAction<_QuitIntent>(
            onInvoke: (_) => exit(0),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: WebViewScreen(
              url: _currentUrl,
              keyboardEnabled: _keyboardEnabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _OpenSettingsIntent extends Intent {
  const _OpenSettingsIntent();
}

class _QuitIntent extends Intent {
  const _QuitIntent();
}
