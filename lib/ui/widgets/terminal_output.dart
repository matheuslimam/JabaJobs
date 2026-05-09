import 'package:flutter/material.dart';

class TerminalOutput extends StatelessWidget {
  const TerminalOutput({super.key, required this.text, this.minHeight = 220});

  final String text;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: minHeight),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C12),
        border: Border.all(color: const Color(0xFF303844)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: SelectableText(
          text.trim().isEmpty ? 'Sem saída ainda.' : text,
          style: const TextStyle(
            fontFamily: 'Consolas',
            fontSize: 13,
            height: 1.35,
            color: Color(0xFFD1D5DB),
          ),
        ),
      ),
    );
  }
}
