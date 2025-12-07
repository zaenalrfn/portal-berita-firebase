import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF0B3D91);
  static final ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: navy,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.blue,
    ).copyWith(primary: navy),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: navy,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: Color(0xFF121212),
    primaryColor: navy,
    colorScheme:
        ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: navy,
          secondary: Colors.blueAccent,
          surface: Color(0xFF1E1E1E),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: Color(0xFF1E1E1E),
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Color(0xFF2C2C2C),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey[600]),
    ),
  );
}
