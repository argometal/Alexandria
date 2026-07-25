import 'package:flutter/material.dart';

/// Barra visible + texto: [bar] en 0..1. Si [useBlueFullBar], barra a 1.0 (p. ej. reten. >1).
class MetricBar extends StatelessWidget {
  const MetricBar({
    super.key,
    required this.label,
    required this.valueText,
    required this.bar,
    this.useBlueFullBar = false,
  });

  final String label;
  final String valueText;
  final double bar; // 0..1
  final bool useBlueFullBar;

  @override
  Widget build(BuildContext context) {
    var b = bar.isNaN ? 0.0 : bar.clamp(0.0, 1.0);
    if (useBlueFullBar) {
      b = 1.0;
    }
    late Color c;
    if (useBlueFullBar) {
      c = const Color(0xFF5B8FD4);
    } else if (b >= 0.75) {
      c = const Color(0xFF2E7D4A);
    } else if (b >= 0.45) {
      c = const Color(0xFF9E8A3C);
    } else {
      c = const Color(0xFF8B3A3A);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 14)),
              ),
              Text(
                valueText,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: b),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, x, _) {
                return LinearProgressIndicator(
                  value: x,
                  minHeight: 10,
                  color: c,
                  backgroundColor: Colors.white10,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
