import 'package:flutter/material.dart';
import 'package:scamshield_mobile/core/theme/app_theme.dart';
import 'package:scamshield_mobile/ui/home/home_screen.dart';

class ScamShieldApp extends StatefulWidget {
  const ScamShieldApp({super.key});

  @override
  State<ScamShieldApp> createState() => _ScamShieldAppState();
}

class _ScamShieldAppState extends State<ScamShieldApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamShield',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: HomeScreen(
        onLightModeChanged: (enabled) => setState(() {
          _themeMode = enabled ? ThemeMode.light : ThemeMode.dark;
        }),
      ),
    );
  }
}
