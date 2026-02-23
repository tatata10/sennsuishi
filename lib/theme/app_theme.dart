import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Main Colors
  static const Color navy = Color(0xFF003366);
  static const Color mintGreen = Color(0xFF66FFCC); // Vibrant Mint
  static const Color white = Colors.white;
  static const Color lightGrey = Color(0xFFF5F5F5); // Background
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color errorRed = Color(0xFFD32F2F);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightGrey,
      primaryColor: navy,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navy,
        primary: navy,
        secondary: mintGreen,
        background: lightGrey,
        surface: white,
        error: errorRed,
      ),
      // fontFamily: 'NotoSansJP',
      textTheme: GoogleFonts.notoSansJpTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSansJp(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: navy,
        ),
        titleLarge: GoogleFonts.notoSansJp(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.notoSansJp(
          fontSize: 18, // Larger for readability
          color: textDark,
        ),
        labelLarge: GoogleFonts.notoSansJp(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navy,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
