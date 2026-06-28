import 'package:flutter/material.dart';

typedef KeyCallback = void Function(String key);

class VirtualKeyboard extends StatefulWidget {
  final KeyCallback onKey;
  final VoidCallback onDismiss;

  const VirtualKeyboard({super.key, required this.onKey, required this.onDismiss});

  @override
  State<VirtualKeyboard> createState() => _VirtualKeyboardState();
}

class _VirtualKeyboardState extends State<VirtualKeyboard> {
  bool _shifted = false;
  bool _capsLock = false;

  static const _rows = [
    ['1','2','3','4','5','6','7','8','9','0','-','='],
    ['q','w','e','r','t','y','u','i','o','p','[',']'],
    ['a','s','d','f','g','h','j','k','l',';',"'"],
    ['z','x','c','v','b','n','m',',','.','/'],
  ];

  static const _shiftMap = {
    '1':'!','2':'@','3':'#','4':'\$','5':'%',
    '6':'^','7':'&','8':'*','9':'(','0':')',
    '-':'_','=':'+','[':'{',']':'}',';':':',
    "'":'"',',':'<','.':'>','/':'?',
  };

  bool get _upper => _capsLock ^ _shifted;

  void _tap(String key) {
    final out = _upper ? (_shiftMap[key] ?? key.toUpperCase()) : (_shiftMap.containsKey(key) && _shifted ? _shiftMap[key]! : key);
    widget.onKey(out);
    if (_shifted && !_capsLock) setState(() => _shifted = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1E),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._rows.asMap().entries.map((e) => _buildRow(e.key, e.value)),
          const SizedBox(height: 6),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildRow(int rowIndex, List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (rowIndex == 2)
            _specialKey('CAPS', 52, active: _capsLock, onTap: () => setState(() { _capsLock = !_capsLock; _shifted = false; })),
          ...keys.map((k) => _charKey(k)),
          if (rowIndex == 2)
            _specialKey('⌫', 70, onTap: () => widget.onKey('BACKSPACE')),
          if (rowIndex == 3) ...[
            _specialKey('⇧', 62, active: _shifted, onTap: () => setState(() => _shifted = !_shifted)),
            ...keys.map((k) => _charKey(k)),
            _specialKey('⇧', 62, active: _shifted, onTap: () => setState(() => _shifted = !_shifted)),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _specialKey('✕', 52, onTap: widget.onDismiss, color: const Color(0xFF3A3A3C)),
        const SizedBox(width: 6),
        Expanded(
          child: GestureDetector(
            onTap: () => widget.onKey(' '),
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF48484A),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text('SPASI', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _specialKey('↵', 72, onTap: () => widget.onKey('ENTER'), color: const Color(0xFF0A84FF)),
      ],
    );
  }

  Widget _charKey(String k) {
    final label = _upper ? (_shiftMap[k] ?? k.toUpperCase()) : (_shifted && _shiftMap.containsKey(k) ? _shiftMap[k]! : k);
    return GestureDetector(
      onTap: () => _tap(k),
      child: Container(
        width: 36,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF48484A),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _specialKey(String label, double width, {VoidCallback? onTap, bool active = false, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0A84FF) : (color ?? const Color(0xFF3A3A3C)),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
