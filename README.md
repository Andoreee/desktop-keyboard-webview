# Desktop Keyboard WebView

Aplikasi kiosk Windows yang menampilkan WebView fullscreen dengan virtual keyboard dan konfigurasi URL.

## Instalasi

1. Download artifact `windows-build.zip` dari GitHub Actions
2. Extract ke folder permanen, misal `C:\Apps\desktop-keyboard-webview\`
3. Jalankan `desktop_keyboard_webview.exe`

## Auto Start saat Boot

1. Tekan `Win+R` → ketik `shell:startup` → Enter
2. Buat shortcut `desktop_keyboard_webview.exe` ke folder yang terbuka

## Konfigurasi

Edit file `config.json` di folder yang sama dengan `.exe` menggunakan Notepad:

```json
{
  "url": "https://example.com",
  "keyboard_enabled": true
}
```

File ini otomatis dibuat saat pertama kali menyimpan pengaturan dari dalam app.

## Shortcut Tersembunyi

| Shortcut | Fungsi |
|---|---|
| `Ctrl+Shift+S` | Buka halaman pengaturan |
| `Ctrl+Shift+Q` | Keluar dari aplikasi |

## Persyaratan

- Windows 10/11
- [WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)
