import 'package:flutter/material.dart';

import '../widgets/press_feedback.dart';

class AppTheme {
  AppTheme._();

  static final _buttonStyle = ButtonStyle(
    splashFactory: InkRipple.splashFactory,
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return Colors.transparent;
      if (states.contains(WidgetState.pressed)) {
        return const Color(0x55073C91);
      }
      if (states.contains(WidgetState.focused) ||
          states.contains(WidgetState.hovered)) {
        return const Color(0x22073C91);
      }
      return null;
    }),
    backgroundBuilder: (context, states, child) => PressFeedback(
      enabled: !states.contains(WidgetState.disabled),
      child: child ?? const SizedBox.shrink(),
    ),
  );

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B8E70),
        ),
        useMaterial3: true,
        splashFactory: InkRipple.splashFactory,
        splashColor: const Color(0x661684E6),
        highlightColor: const Color(0x331684E6),
        filledButtonTheme: FilledButtonThemeData(style: _buttonStyle),
        outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle),
        textButtonTheme: TextButtonThemeData(style: _buttonStyle),
        elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
        iconButtonTheme: IconButtonThemeData(style: _buttonStyle),
      );
}
