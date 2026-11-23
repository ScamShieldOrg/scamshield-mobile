import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/auth_state.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_form_card.dart';
import 'login_viewmodel.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginViewModel>(
      create: (context) => LoginViewModel(
        authRepository: context.read<AuthRepository>(),
        authState: context.read<AuthState>(),
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  void _showInfoMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đăng nhập',
          style: TextStyle(
            fontFamily: 'sans-serif',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LoginFormCard(
                    onLoginSuccess: () {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Đăng nhập thành công.'),
                          ),
                        );
                      if (navigator.canPop()) {
                        navigator.pop(true);
                      }
                    },
                    onForgotPassword: () => _showInfoMessage(
                      context,
                      'Tính năng khôi phục mật khẩu trên di động đang được phát triển.',
                    ),
                    onGoogleSignIn: () => _showInfoMessage(
                      context,
                      'Đăng nhập Google trên di động cần cấu hình OAuth (Firebase / Google Sign-In).',
                    ),
                    onRegister: () => _showInfoMessage(
                      context,
                      'Màn hình đăng ký trên di động đang được phát triển.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: AppTheme.mutedInk,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Cam kết chuẩn bảo mật Zero-PII • ScamShield Vietnam',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 11.5,
                            color: AppTheme.mutedInk,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
