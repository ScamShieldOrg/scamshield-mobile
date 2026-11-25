import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scamshield_mobile/app/auth_state.dart';
import 'package:scamshield_mobile/app/user_quota_state.dart';
import 'package:scamshield_mobile/core/theme/app_theme.dart';
import 'package:scamshield_mobile/data/repositories/auth_repository.dart';
import 'package:scamshield_mobile/data/repositories/dispute_repository.dart';
import 'package:scamshield_mobile/data/repositories/user_quota_repository.dart';
import 'package:scamshield_mobile/ui/home/home_screen.dart';

class ScamShieldApp extends StatelessWidget {
  const ScamShieldApp({
    super.key,
    this.authRepository,
    this.userQuotaRepository,
    this.disputeRepository,
    this.restoreSessionOnStart = true,
  });

  final AuthRepository? authRepository;
  final UserQuotaRepository? userQuotaRepository;
  final DisputeRepository? disputeRepository;
  final bool restoreSessionOnStart;

  @override
  State<ScamShieldApp> createState() => _ScamShieldAppState();
}

class _ScamShieldAppState extends State<ScamShieldApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    final repository = authRepository ?? AuthRepository();
    final quotaRepository = userQuotaRepository ?? UserQuotaRepository();
    final disputes = disputeRepository ?? DisputeRepository();

    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: repository),
        Provider<UserQuotaRepository>.value(value: quotaRepository),
        Provider<DisputeRepository>.value(value: disputes),
        ChangeNotifierProvider<AuthState>(
          create: (_) {
            final state = AuthState(authRepository: repository);
            if (restoreSessionOnStart) {
              state.initialize();
            }
            return state;
          },
        ),
        ChangeNotifierProxyProvider<AuthState, UserQuotaState>(
          create: (_) => UserQuotaState(quotaRepository: quotaRepository),
          update: (_, authState, quotaState) {
            final state =
                quotaState ?? UserQuotaState(quotaRepository: quotaRepository);
            state.syncAccessToken(authState.session?.accessToken);
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
