import 'package:flutter/material.dart';

import '../models/protocol_config.dart';

String _hintText(String modality) {
  if (modality == ProtocolConfig.modalityCards) {
    return 'Pares: AS-2H | 3C-4D | ... (| entre pares, - entre cartas)';
  }
  return 'Números: 12 34 56 ... (espacios, siempre 00-99 con dos cifras)';
}

class SequenceInputField extends StatelessWidget {
  const SequenceInputField({
    super.key,
    required this.modality,
    required this.controller,
  });

  final String modality;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 6,
      style: const TextStyle(fontFamily: 'monospace'),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        hintText: _hintText(modality),
      ),
    );
  }
}
