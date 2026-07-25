import 'package:flutter/material.dart';

import '../services/session_store.dart';

class MethodologyScreen extends StatelessWidget {
  const MethodologyScreen({super.key, required this.store});

  final SessionStore store;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metodología del protocolo'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _Section(
            title: 'Flujo de una sesión',
            body:
                '1) Encode: ajustas en inicio los segundos por estímulo (1–10 s) y fijas sin responder.\n'
                '2) Recall: marcas Bien / Difícil / Fallo y repites (ordenar o escribir).\n'
                '3) Pausa con cuenta atrás: duración ajustable en inicio (20 s–3 min). Skip sigue existiendo. Luego recall diferido (igual).\n'
                '4) Resultados: orden correcto numerado, tabla inmediata vs. encode y tabla diferida, barras de % y score, latencia. Guardar añade fila al CSV. Inicio y Avance muestran progreso visible (medias, gráfica de score al tener ≥2 filas).',
          ),
          const _Section(
            title: 'Qué significa cada métrica',
            body:
                '• acc inmediata / acc diferida: qué tan bien acertaste en cada fase (posición y estímulo correctos, según modalidad).\n'
                '• retention (d/i): qué queda de lo que recordaste al instante respecto a lo recordado más tarde (0–1+; >1 implica mejora relativa en diferido).\n'
                '• score_norm: resumen con techo 1, útil para comparar sesiones con la misma longitud y modalidad; úsalo como “avance resumido”, no como examen clínico.',
          ),
          _Section(
            title: 'Datos en el dispositivo',
            body:
                'Cada evento (encode y cada recall) se añade a un archivo JSONL por sesión, en la carpeta de soporte de la app, sin salir a internet.\n\n'
                'Carpeta base: ${store.dataRootPath}\n'
                '  • training_app/sessions/ — un .jsonl por session_id\n'
                '  • training_app/metrics/daily.csv — filas añadidas al pulsar “Guardar CSV…” en resultados',
          ),
          const _Section(
            title: 'Cómo ver progreso',
            body:
                'Abre “Avance” en la pantalla inicial. Ahí se listan las filas de daily.csv: fecha, score_norm, accuracies y retención. Tendrás señal de avance con varias sesiones guardadas (mejor: misma longitud y modalidad durante un tiempo).',
          ),
          const _Section(
            title: 'Vista rápida y modo ordenar',
            body:
                'Vista rápida: vuelve a enseñar la secuencia; queda anotada en contexto (peek_reference_used).\n'
                'En modo Ordenar, los ítems se muestran en orden aleatorio; tú reordenas a lo que recuerdes — sin teclado. Modo Escribir conserva el sistema de texto (útil en escritorio o si prefieres teclear).',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(height: 1.45, color: Colors.white70)),
        ],
      ),
    );
  }
}
