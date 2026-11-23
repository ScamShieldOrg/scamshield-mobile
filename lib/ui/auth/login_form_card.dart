import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import 'google_logo_icon.dart';
import 'login_validation.dart';
import 'login_viewmodel.dart';

class LoginFormCard extends StatefulWidget {
  const LoginFormCard({
    super.key,
    required this.onLoginSuccess,
    required this.onForgotPassword,
    required this.onGoogleSignIn,
    required this.onRegister,
  });

  final VoidCallback onLoginSuccess;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onRegister;

  @override
  State<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends State<LoginFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _loadRememberedIdentifier();
  }

  Future<void> _loadRememberedIdentifier() async {
    final viewModel = context.read<LoginViewModel>();
    final saved = await viewModel.loadRememberedIdentifier();
    if (!mounted || saved == null || saved.isEmpty) {
      return;
    }
    if (_identifierController.text.isEmpty) {
      _identifierController.text = saved;
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final form = _formKey.currentState;
    if (form == null) {
      return;
    }
    if (!form.validate()) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
      });
      return;
    }

    FocusScope.of(context).unfocus();
    final viewModel = context.read<LoginViewModel>();
    final success = await viewModel.submit(
      identifier: _identifierController.text,
      password: _passwordController.text,
    );
    if (!mounted) {
      return;
    }
    if (success) {
      widget.onLoginSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LoginViewModel>();
    final baseTheme = Theme.of(context);
    final formTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: 'sans-serif'),
    );
    final errorMessage = viewModel.errorMessage;
    final isSubmitting = viewModel.isSubmitting;

    return Theme(
      data: formTheme,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Đăng Nhập',
                    style: formTheme.textTheme.headlineMedium?.copyWith(
                      fontFamily: 'sans-serif',
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                const SizedBox(height: 20),
                if (errorMessage != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.errorBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.error_outline,
                              size: 18,
                              color: AppTheme.error,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: const TextStyle(
                                fontFamily: 'sans-serif',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Số điện thoại hoặc Email',
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('login_identifier_field'),
                  controller: _identifierController,
                  enabled: !isSubmitting,
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 15,
                    color: AppTheme.ink,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                    AutofillHints.telephoneNumber,
                  ],
                  autocorrect: false,
                  onChanged: (_) => viewModel.clearError(),
                  onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                  validator: validateLoginIdentifier,
                  decoration: _fieldDecoration(
                    hintText: 'Ví dụ: 0912345678 hoặc email@domain.vn',
                    prefixIcon: Icons.person_outline,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mật khẩu bảo mật',
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('login_password_field'),
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  enabled: !isSubmitting,
                  style: const TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 15,
                    color: AppTheme.ink,
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (_) => viewModel.clearError(),
                  onFieldSubmitted: (_) => _handleSubmit(),
                  validator: validateLoginPassword,
                  decoration: _fieldDecoration(
                    hintText: '••••••••••••',
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Hiện mật khẩu'
                          : 'Ẩn mật khẩu',
                      onPressed: isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.mutedInk,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        key: const ValueKey('login_remember_checkbox'),
                        value: viewModel.rememberMe,
                        activeColor: AppTheme.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: isSubmitting
                            ? null
                            : (value) =>
                                  viewModel.setRememberMe(value ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: isSubmitting
                            ? null
                            : () => viewModel.setRememberMe(
                                !viewModel.rememberMe,
                              ),
                        child: const Text(
                          'Ghi nhớ đăng nhập',
                          style: TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 13,
                            color: AppTheme.mutedInk,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: isSubmitting ? null : widget.onForgotPassword,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppTheme.mutedInk,
                      ),
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton(
                  key: const ValueKey('login_submit_button'),
                  onPressed: isSubmitting ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppTheme.navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.navy.withValues(
                      alpha: 0.72,
                    ),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSubmitting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      else
                        const Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: AppTheme.shieldBlue,
                        ),
                      const SizedBox(width: 10),
                      Text(
                        isSubmitting ? 'Đang xử lý...' : 'Đăng Nhập',
                        style: const TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!isSubmitting) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 17),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'HOẶC TIẾP TỤC VỚI',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                          color: AppTheme.mutedInk,
                        ),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  key: const ValueKey('login_google_button'),
                  onPressed: isSubmitting ? null : widget.onGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.ink,
                    side: const BorderSide(color: AppTheme.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GoogleLogoIcon(size: 19),
                      SizedBox(width: 10),
                      Text(
                        'Đăng nhập với Google',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(
                        fontFamily: 'sans-serif',
                        fontSize: 13.5,
                        color: AppTheme.mutedInk,
                      ),
                    ),
                    TextButton(
                      onPressed: isSubmitting ? null : widget.onRegister,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: AppTheme.ink,
                      ),
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
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

  InputDecoration _fieldDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 14,
        color: AppTheme.mutedInk.withValues(alpha: 0.72),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'sans-serif',
        fontSize: 12,
        color: AppTheme.error,
      ),
      prefixIcon: Icon(prefixIcon, size: 19, color: AppTheme.mutedInk),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppTheme.page,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.navy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
    );
  }
}
