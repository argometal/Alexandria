import 'package:flutter/material.dart';

/// Tema LibraryBuild alineado con la paleta GateKeeper / póster Alexandria:
/// piedra oscura, oro/ámbar, azul hielo, cielo nocturno.
abstract final class AlexandriaLbTheme {
  AlexandriaLbTheme._();

  static const Color iceBlue = Color(0xFFA0C4FF);
  static const Color gold = Color(0xFFF5C563);
  static const Color stoneDeep = Color(0xFF1A1512);

  /// Carril lateral del editor: enlaces / hero / collage / texto (contraste en fondo oscuro).
  static const Color blockRailLink = Color(0xFFFFB04D);
  static const Color blockRailHero = Color(0xFF78A8FF);
  static const Color blockRailCollage = Color(0xFF9CAD7A);
  static const Color blockRailImage = Color(0xFF7A8B9E);
  static const Color blockRailPlace = Color(0xFFD4A574);
  static const Color blockRailHint = Color(0xFFB89FC9);
  static const Color blockRailRidiculous = Color(0xFFE8A4B8);
  static const Color blockRailTextDefault = Color(0xFF8CB8E8);
  /// Bloque tarjeta (vocabulario / idiomas): acento ámbar.
  static const Color blockRailCard = Color(0xFFE5A84A);

  /// Chips de bloque imagen (fondo oscuro, acento suave).
  static const Color chipHeroBg = Color(0xFF2A3548);
  static const Color chipCollageBg = Color(0xFF2B3830);
  static const Color chipImageBg = Color(0xFF3D3834);

  static ColorScheme get colorScheme {
    final fromSeed = ColorScheme.fromSeed(
      seedColor: const Color(0xFFE8AC3D),
      brightness: Brightness.dark,
    );
    return fromSeed.copyWith(
      secondary: iceBlue,
      onSecondary: const Color(0xFF0D1526),
      secondaryContainer: const Color(0xFF2D3648),
      onSecondaryContainer: const Color(0xFFD8E6FF),
      tertiary: const Color(0xFFE59B2F),
      onTertiary: const Color(0xFF1F1408),
      tertiaryContainer: const Color(0xFF4A3820),
      onTertiaryContainer: const Color(0xFFFFE2B8),
      surface: const Color(0xFF1E1A16),
      surfaceContainerLowest: stoneDeep,
      surfaceContainerLow: const Color(0xFF1C1815),
      surfaceContainer: const Color(0xFF231E1A),
      surfaceContainerHigh: const Color(0xFF2C2621),
      surfaceContainerHighest: const Color(0xFF383028),
      outline: const Color(0xFF5C5248),
      outlineVariant: const Color(0xFF443C34),
    );
  }

  static ThemeData get theme => ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: stoneDeep,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: const Color(0xFF211C18),
          foregroundColor: gold,
          surfaceTintColor: Colors.transparent,
          iconTheme: const IconThemeData(color: gold),
          titleTextStyle: const TextStyle(
            color: gold,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF2A241E),
          surfaceTintColor: Colors.transparent,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF342C26),
          contentTextStyle: const TextStyle(color: Color(0xFFE8E0D8)),
          actionTextColor: gold,
        ),
      );
}
