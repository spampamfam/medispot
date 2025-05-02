import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/start_screen.dart';
import 'constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Ensure fonts are loaded
  GoogleFonts.config.allowRuntimeFetching = true;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine current locale
    final isArabic = context.locale.languageCode == 'ar';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'app_name'.tr(),
      theme: ThemeData(
        // Use Poppins for English, Noto Sans Arabic for Arabic
        textTheme: isArabic
            ? _buildArabicTextTheme(Theme.of(context).textTheme)
            : GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: isArabic
              ? const TextStyle(
                  fontFamily: 'Noto Sans Arabic',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )
              : GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
        ),
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: StartScreen(),
    );
  }

  TextTheme _buildArabicTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(fontFamily: 'Noto Sans Arabic'),
      displayMedium:
          base.displayMedium?.copyWith(fontFamily: 'Noto Sans Arabic'),
      displaySmall: base.displaySmall?.copyWith(fontFamily: 'Noto Sans Arabic'),
      headlineLarge:
          base.headlineLarge?.copyWith(fontFamily: 'Noto Sans Arabic'),
      headlineMedium:
          base.headlineMedium?.copyWith(fontFamily: 'Noto Sans Arabic'),
      headlineSmall:
          base.headlineSmall?.copyWith(fontFamily: 'Noto Sans Arabic'),
      titleLarge: base.titleLarge?.copyWith(fontFamily: 'Noto Sans Arabic'),
      titleMedium: base.titleMedium?.copyWith(fontFamily: 'Noto Sans Arabic'),
      titleSmall: base.titleSmall?.copyWith(fontFamily: 'Noto Sans Arabic'),
      bodyLarge: base.bodyLarge?.copyWith(fontFamily: 'Noto Sans Arabic'),
      bodyMedium: base.bodyMedium?.copyWith(fontFamily: 'Noto Sans Arabic'),
      bodySmall: base.bodySmall?.copyWith(fontFamily: 'Noto Sans Arabic'),
      labelLarge: base.labelLarge?.copyWith(fontFamily: 'Noto Sans Arabic'),
      labelMedium: base.labelMedium?.copyWith(fontFamily: 'Noto Sans Arabic'),
      labelSmall: base.labelSmall?.copyWith(fontFamily: 'Noto Sans Arabic'),
    );
  }
}
