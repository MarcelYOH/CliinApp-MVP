import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CliinAppTextStyles {
  CliinAppTextStyles._();

  // ── Titres (Poppins) ──
  static TextStyle headingLarge = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF1B4332),
    height: 1.25,
  );

  static TextStyle headingMedium = GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF1B4332),
    height: 1.25,
  );

  static TextStyle headingSmall = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF1A1A1A),
    height: 1.3,
  );

  // ── Corps / descriptions (Inter) ──
  static TextStyle bodyMedium = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF6B7280),
    height: 1.5,
  );

  static TextStyle bodySmall = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: const Color(0xFF6B7280),
    height: 1.5,
  );

  // ── Labels / badges ──
  static TextStyle badge = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF2E7D32),
  );

  // ── Boutons ──
  static TextStyle button = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: const Color(0xFFFFFFFF),
  );

  // ── Texte lien ──
  static TextStyle link = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF4CAF50),
  );
}