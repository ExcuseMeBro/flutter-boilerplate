import 'package:flutter/material.dart';

/// The game's semantic palette. Tile colors are stable in both themes.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.background,
    required this.surface,
    required this.board,
    required this.slot,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.outline,
  });

  final Color background,
      surface,
      board,
      slot,
      ink,
      muted,
      accent,
      onAccent,
      outline;

  @override
  GameColors copyWith({
    Color? background,
    Color? surface,
    Color? board,
    Color? slot,
    Color? ink,
    Color? muted,
    Color? accent,
    Color? onAccent,
    Color? outline,
  }) => GameColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    board: board ?? this.board,
    slot: slot ?? this.slot,
    ink: ink ?? this.ink,
    muted: muted ?? this.muted,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    outline: outline ?? this.outline,
  );

  @override
  GameColors lerp(ThemeExtension<GameColors>? other, double t) {
    if (other is! GameColors) return this;
    return GameColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      board: Color.lerp(board, other.board, t)!,
      slot: Color.lerp(slot, other.slot, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
    );
  }
}

class GameTokens {
  const GameTokens._();
  static const pagePadding = 24.0;
  static const gap = 10.0;
  static const boardPadding = 12.0;
  static const boardRadius = 28.0;
  static const tileRadius = 17.0;
  static const cardRadius = 20.0;
  static const controlHeight = 54.0;
  static const slideDuration = Duration(milliseconds: 155);
  static const popDuration = Duration(milliseconds: 180);

  static const tileColors = <Color>[
    Color(0xFFECE8DF),
    Color(0xFFE9D8BD),
    Color(0xFFF5BB72),
    Color(0xFFF29B67),
    Color(0xFFEB7D69),
    Color(0xFFDD6E78),
    Color(0xFFC18FCE),
    Color(0xFF9C9ADE),
    Color(0xFF7FADE0),
    Color(0xFF66BDB9),
    Color(0xFFE6C66D),
    Color(0xFFE6B453),
  ];
  static const tileInk = Color(0xFF101928);
}

class AppTheme {
  const AppTheme._();

  static const _light = GameColors(
    background: Color(0xFFF7F5F0),
    surface: Color(0xFFFFFFFF),
    board: Color(0xFF28364D),
    slot: Color(0xFF3D4A5D),
    ink: Color(0xFF202D40),
    muted: Color(0xFF59687B),
    accent: Color(0xFFB65D29),
    onAccent: Color(0xFFFFFFFF),
    outline: Color(0xFFDBE0E3),
  );
  static const _dark = GameColors(
    background: Color(0xFF131F30),
    surface: Color(0xFF202E42),
    board: Color(0xFF2B3A50),
    slot: Color(0xFF3B4960),
    ink: Color(0xFFF8F5ED),
    muted: Color(0xFFAFBDCC),
    accent: Color(0xFFFFCA7E),
    onAccent: Color(0xFF202D40),
    outline: Color(0xFF45536A),
  );

  static ThemeData get light => _theme(Brightness.light, _light);
  static ThemeData get dark => _theme(Brightness.dark, _dark);

  static ThemeData _theme(Brightness brightness, GameColors colors) {
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.accent,
      brightness: brightness,
      surface: colors.background,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 68,
          fontWeight: FontWeight.w900,
          letterSpacing: -4,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -.7,
        ),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
