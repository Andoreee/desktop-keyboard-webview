import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final bool keyboardEnabled;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.keyboardEnabled,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final _controller = WebviewController();
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didUpdateWidget(WebViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url && _isInitialized) {
      _controller.loadUrl(widget.url);
    }
    if (oldWidget.keyboardEnabled != widget.keyboardEnabled && _isInitialized) {
      _applyKeyboardSetting();
    }
  }

  Future<void> _initWebView() async {
    try {
      await _controller.initialize();
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      _controller.loadingState.listen((state) {
        if (state == LoadingState.navigationCompleted) _onPageLoaded();
      });
      _controller.webMessage.listen(_onWebMessage);

      await _controller.loadUrl(widget.url);

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() { _hasError = true; _errorMessage = e.toString(); });
    }
  }

  void _onWebMessage(dynamic message) {
    if (message == 'kb_show') {
      Process.run('cmd', ['/c', 'start', '', r'C:\Program Files\Common Files\microsoft shared\ink\TabTip.exe']);
    } else if (message == 'kb_hide') {
      Process.run('taskkill', ['/f', '/im', 'TabTip.exe']);
    }
  }

  void _onPageLoaded() {
    _applyScrollFix();
    _applyKeyboardSetting();
  }

  void _applyScrollFix() {
    // Enable touch/pointer scroll
    _controller.executeScript('''
      document.documentElement.style.touchAction = 'pan-x pan-y';
      document.body.style.touchAction = 'pan-x pan-y';
      document.body.style.overflowY = 'auto';
    ''');
  }

  void _applyKeyboardSetting() {
    // Reset guard dulu agar listener lama tidak blocking
    _controller.executeScript('window.__kbGuard = false;');

    if (!widget.keyboardEnabled) {
      _controller.executeScript('''
        (function() {
          if (window.__kbGuard) return;
          window.__kbGuard = true;
          document.addEventListener('focus', e => {
            if (e.target.matches('input,textarea,[contenteditable]')) {
              e.target.blur(); e.preventDefault();
            }
          }, true);
          document.addEventListener('click', e => {
            if (e.target.matches('input,textarea,[contenteditable]'))
              setTimeout(() => e.target.blur(), 10);
          }, true);
        })();
      ''');
    } else {
      _controller.executeScript('''
        (function() {
          if (window.__kbGuard) return;
          window.__kbGuard = true;
          document.addEventListener('focus', e => {
            if (e.target.matches('input,textarea,[contenteditable]'))
              window.chrome.webview.postMessage('kb_show');
          }, true);
          document.addEventListener('blur', e => {
            if (e.target.matches('input,textarea,[contenteditable]'))
              window.chrome.webview.postMessage('kb_hide');
          }, true);
        })();
      ''');
    }
  }

  // Scroll 2 jari via pointer signal
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _controller.executeScript('''
        window.scrollBy(${event.scrollDelta.dx}, ${event.scrollDelta.dy});
      ''');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _buildErrorView();
    if (!_isInitialized) return _buildLoadingView();

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: Webview(
        _controller,
        permissionRequested: (url, permissionKind, isUserInitiated) =>
            WebviewPermissionDecision.allow,
      ),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2196F3), strokeWidth: 2),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: Colors.white54, fontSize: 14, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text('WebView Error', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_errorMessage, style: const TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            const Text('Pastikan WebView2 Runtime sudah terinstall.', style: TextStyle(color: Colors.orange, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() { _hasError = false; _isInitialized = false; });
                _initWebView();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
