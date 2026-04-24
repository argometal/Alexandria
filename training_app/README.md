# training_app

Aplicación Flutter **independiente** (tercer motor de entrenamiento). Escribe `session_*.jsonl` y `metrics/daily.csv` bajo el directorio de **soporte** de la aplicación (p. ej. en Windows, `%APPDATA%\com.alexandria\training_app\` vía `path_provider`).

**No** forma parte de `LibraryBuild/`, `GateKeeper/`, `data/` ni bridge. Etiqueta de hilo: `[ACUERDO_CHAT_DEEP]`.

## Ejecución

```sh
cd training_app
flutter pub get
flutter run -d windows
```

## Protocolo v1

- Cartas: pares de cartas únicos (`AS-2H` = dos cartas), secuencia horizontal con `|`.
- Números: 00-99, sin repetición en la sesión; entrada separada por espacios.
- `score_norm = min(accuracy * (1000 / avg_latency_ms), 1.0)`.

## Integración futura con Alexandria

Llamada externa: launcher, deep link, o empaquetar junto; los datos viven en JSON/CSV y pueden importarse a un módulo LB sin tocar el núcleo hasta acuerdo explícito de ORM.
