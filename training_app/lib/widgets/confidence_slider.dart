import 'package:flutter/material.dart';

class ConfidenceBlock extends StatefulWidget {
  const ConfidenceBlock({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<ConfidenceBlock> createState() => _ConfidenceBlockState();
}

class _ConfidenceBlockState extends State<ConfidenceBlock> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Confianza: ${(widget.value * 100).round()}%'),
        Slider(
          value: widget.value,
          onChanged: widget.onChanged,
          min: 0,
          max: 1.0,
          divisions: 20,
        ),
      ],
    );
  }
}
