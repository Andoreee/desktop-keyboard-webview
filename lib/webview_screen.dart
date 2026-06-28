import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'virtual_keyboard.dart';

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
  bool _showKeyboard = false;

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
      if (!widget.keyboardEnabled) setState(() => _showKeyboard = false);
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
    if (!widget.keyboardEnabled) return;
    if (message == 'kb_show') {
      setState(() => _showKeyboard = true);
    } else if (message == 'kb_hide') {
      setState(() => _showKeyboard = false);
    }
  }

  void _onPageLoaded() {
    _applyScrollFix();
    _applyKeyboardSetting();
  }

  void _applyScrollFix() {
    _controller.executeScript('''
      document.documentElement.style.touchAction = 'pan-x pan-y';
      document.body.style.touchAction = 'pan-x pan-y';
      document.body.style.overflowY = 'auto';
    ''');
  }

  void _applyKeyboardSetting() {
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
      // ponytail: blur() prevents native OSK from popping up; we handle input ourselves
      _controller.executeScript('''
        (function() {
          if (window.__kbGuard) return;
          window.__kbGuard = true;
          document.addEventListener('focus', e => {
            if (e.target.matches('input,textarea,[contenteditable]')) {
              e.target.blur();
              window.__activeInput = e.target;
              window.chrome.webview.postMessage('kb_show');
            }
          }, true);
          document.addEventListener('click', e => {
            if (e.target.matches('input,textarea,[contenteditable]')) {
              window.__activeInput = e.target;
              window.chrome.webview.postMessage('kb_show');
            }
          }, true);
        })();
      ''');
    }
  }

  void _onVirtualKey(String key) {
    String js;
    if (key == 'BACKSPACE') {
      js = '''
        (function() {
          var el = window.__activeInput;
          if (!el) return;
          var v = el.value;
          if (v && v.length > 0) {
            el.value = v.slice(0, -1);
            el.dispatchEvent(new Event('input', {bubbles:true}));
          } else if (el.isContentEditable) {
            document.execCommand('delete');
          }
        })();
      ''';
    } else if (key == 'ENTER') {
      js = '''
        (function() {
          var el = window.__activeInput;
          if (!el) return;
          if (el.tagName === 'INPUT') {
            el.dispatchEvent(new KeyboardEvent('keydown', {key:'Enter',code:'Enter',bubbles:true}));
            el.form && el.form.requestSubmit && el.form.requestSubmit();
          } else {
            el.value = (el.value||'') + '\\n';
            el.dispatchEvent(new Event('input', {bubbles:true}));
          }
        })();
      ''';
    } else {
      final escaped = key.replaceAll("'", r"\'").replaceAll('\\', '\\\\');
      js = '''
        (function() {
          var el = window.__activeInput;
          if (!el) return;
          if (el.isContentEditable) {
            document.execCommand('insertText', false, '$escaped');
          } else {
            var start = el.selectionStart ?? el.value.length;
            el.value = el.value.slice(0, start) + '$escaped' + el.value.slice(el.selectionEnd ?? start);
            el.selectionStart = el.selectionEnd = start + 1;
            el.dispatchEvent(new Event('input', {bubbles:true}));
          }
        })();
      ''';
    }
    _controller.executeScript(js);
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _controller.executeScript(
        'window.scrollBy(${event.scrollDelta.dx}, ${event.scrollDelta.dy});',
      );
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

    return Column(
      children: [
        Expanded(
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: Webview(
              _controller,
              permissionRequested: (url, permissionKind, isUserInitiated) =>
                  WebviewPermissionDecision.allow,
            ),
          ),
        ),
        if (_showKeyboard)
          VirtualKeyboard(
            onKey: _onVirtualKey,
            onDismiss: () => setState(() => _showKeyboard = false),
          ),
      ],
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
