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

  static const _row0 = ['1','2','3','4','5','6','7','8','9','0','-','='];
  static const _row1 = ['q','w','e','r','t','y','u','i','o','p','[',']'];
  static const _row2 = ['a','s','d','f','g','h','j','k','l',';',"'"];
  static const _row3 = ['z','x','c','v','b','n','m',',','.','/'];

  static const _shiftMap = {
    '1':'!','2':'@','3':'#','4':r'$','5':'%',
    '6':'^','7':'&','8':'*','9':'(','0':')',
    '-':'_','=':'+','[':'{',']':'}',';':':',
    "'":'"',',':'<','.':'>','/':'?',
  };

  bool get _upper => _capsLock ^ _shifted;

  String _label(String k) {
    if (_upper) return _shiftMap[k] ?? k.toUpperCase();
    if (_shifted && _shiftMap.containsKey(k)) return _shiftMap[k]!;
    return k;
  }

  void _tap(String key) {
    widget.onKey(_label(key));
    if (_shifted && !_capsLock) setState(() => _shifted = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2C2C2E),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(_row0),
          _row(_row1),
          // Row 2: CAPS + keys + backspace
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _special('CAPS', 64, active: _capsLock, onTap: () => setState(() { _capsLock = !_capsLock; _shifted = false; })),
                const SizedBox(width: 6),
                ..._row2.map(_charKey),
                const SizedBox(width: 6),
                _special('⌫', 64, onTap: () => widget.onKey('BACKSPACE')),
              ],
            ),
          ),
          // Row 3: shift + keys + shift
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _special('⇧', 80, active: _shifted, onTap: () => setState(() => _shifted = !_shifted)),
                const SizedBox(width: 6),
                ..._row3.map(_charKey),
                const SizedBox(width: 6),
                _special('⇧', 80, active: _shifted, onTap: () => setState(() => _shifted = !_shifted)),
              ],
            ),
          ),
          // Bottom row
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _special('✕', 52, onTap: widget.onDismiss, color: const Color(0xFF636366)),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onKey(' '),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF636366),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text('SPASI', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _special('↵', 72, onTap: () => widget.onKey('ENTER'), color: const Color(0xFF0A84FF)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: keys.map(_charKey).toList(),
      ),
    );
  }

  Widget _charKey(String k) {
    return GestureDetector(
      onTap: () => _tap(k),
      child: Container(
        width: 52,
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF48484A),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(0, 2), blurRadius: 0, spreadRadius: 0)],
        ),
        alignment: Alignment.center,
        child: Text(_label(k), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w400)),
      ),
    );
  }

  Widget _special(String label, double width, {VoidCallback? onTap, bool active = false, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 48,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0A84FF) : (color ?? const Color(0xFF3A3A3C)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0xFF000000), offset: Offset(0, 2), blurRadius: 0, spreadRadius: 0)],
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
