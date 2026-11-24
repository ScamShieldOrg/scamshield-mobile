import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scamshield_mobile/app/auth_state.dart';
import 'package:scamshield_mobile/core/theme/app_theme.dart';
import 'package:scamshield_mobile/data/repositories/auth_repository.dart';
import 'package:scamshield_mobile/ui/home/home_screen.dart';

class ScamShieldApp extends StatelessWidget {
  const ScamShieldApp({
    super.key,
    this.authRepository,
    this.restoreSessionOnStart = true,
  });

  final AuthRepository? authRepository;
  final bool restoreSessionOnStart;

  @override
  State<ScamShieldApp> createState() => _ScamShieldAppState();
}

class _ScamShieldAppState extends State<ScamShieldApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    final repository = authRepository ?? AuthRepository();

    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: repository),
        ChangeNotifierProvider<AuthState>(
          create: (_) {
            final state = AuthState(authRepository: repository);
            if (restoreSessionOnStart) {
              state.initialize();
            }
            return state;
          },
        ),
      ],
      child: MaterialApp(
        title: 'ScamShield',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const HomeScreen(),
      ),
    );
  }
}
