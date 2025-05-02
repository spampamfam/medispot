import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle getAppTextStyle(
  BuildContext context, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  bool forceArabic = false,
}) {
  final locale = Localizations.localeOf(context).languageCode;
  final isArabic = locale == 'ar' || forceArabic;

  if (isArabic) {
    return TextStyle(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Colors.black,
      fontFamily: 'Noto Sans Arabic',
      fontVariations: [
        if (fontWeight != null)
          FontVariation('wght', fontWeight.index * 100 + 100),
      ],
    );
  } else {
    return GoogleFonts.poppins(
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight ?? FontWeight.normal,
      color: color ?? Colors.black,
    );
  }
}
