import 'package:flutter/material.dart';

import '../../data/services/report_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  String _identifier = '';
  String _password = '';
  String? _error;
  bool _busy = false;

  Future<void> _signIn() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await ReportService().signIn(_identifier.trim(), _password);
      if (mounted) Navigator.of(context).pop(token);
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is FormatException
            ? error.message
            : 'Không thể đăng nhập. Vui lòng kiểm tra kết nối và thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                AutofillGroup(
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          enabled: !_busy,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Tên đăng nhập hoặc số điện thoại',
                          ),
                          onChanged: (value) => _identifier = value,
                          validator: (value) => _identifier.trim().isEmpty
                              ? 'Vui lòng nhập tên đăng nhập hoặc số điện thoại.'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          enabled: !_busy,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu',
                          ),
                          onChanged: (value) => _password = value,
                          validator: (value) => _password.isEmpty
                              ? 'Vui lòng nhập mật khẩu.'
                              : null,
                          onFieldSubmitted: (_) => _signIn(),
                        ),
                        if (_error case final error?) ...[
                          const SizedBox(height: 12),
                          Text(
                            error,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _signIn,
                          child: Text(
                            _busy ? 'Đang đăng nhập...' : 'Đăng nhập',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
