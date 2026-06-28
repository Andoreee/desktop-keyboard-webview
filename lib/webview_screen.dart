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

    // Reload jika URL berubah
    if (oldWidget.url != widget.url && _isInitialized) {
      _controller.loadUrl(widget.url);
    }

    // Toggle virtual keyboard jika setting berubah
    if (oldWidget.keyboardEnabled != widget.keyboardEnabled && _isInitialized) {
      _applyKeyboardSetting();
    }
  }

  Future<void> _initWebView() async {
    try {
      await _controller.initialize();

      // Sembunyikan scrollbar default WebView
      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);

      _applyKeyboardSetting();

      await _controller.loadUrl(widget.url);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Inject JS untuk enable/disable virtual keyboard di web page
  void _applyKeyboardSetting() {
    if (!widget.keyboardEnabled) {
      // Disable keyboard: prevent focus on input fields
      _controller.executeScript('''
        (function() {
          if (window.__keyboardDisabled) return;
          window.__keyboardDisabled = true;

          function preventFocus(e) {
            if (e.target && (e.target.tagName === 'INPUT' || 
                e.target.tagName === 'TEXTAREA' || 
                e.target.isContentEditable)) {
              e.target.blur();
              e.preventDefault();
            }
          }

          document.addEventListener('focus', preventFocus, true);
          document.addEventListener('click', function(e) {
            if (e.target && (e.target.tagName === 'INPUT' || 
                e.target.tagName === 'TEXTAREA' || 
                e.target.isContentEditable)) {
              setTimeout(() => e.target.blur(), 10);
            }
          }, true);
        })();
      ''');
    } else {
      // Re-enable keyboard: remove event listeners via reload approach
      _controller.executeScript('''
        (function() {
          if (window.__keyboardDisabled) {
            window.__keyboardDisabled = false;
            // Reload halaman untuk reset semua listener
            window.location.reload();
          }
        })();
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
    if (_hasError) {
      return _buildErrorView();
    }

    if (!_isInitialized) {
      return _buildLoadingView();
    }

    return Webview(
      _controller,
      permissionRequested: (url, permissionKind, isUserInitiated) =>
          WebviewPermissionDecision.allow,
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFF2196F3),
              strokeWidth: 2,
            ),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
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
            const Text(
              'WebView Error',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Pastikan WebView2 Runtime sudah terinstall.',
              style: TextStyle(color: Colors.orange, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isInitialized = false;
                });
                _initWebView();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
