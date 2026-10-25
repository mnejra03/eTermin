import 'package:flutter/material.dart';

import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _apiService = ApiService();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _codeRequested = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Unesite ispravnu email adresu.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.requestPasswordResetCode(email);
      if (!mounted) return;
      setState(() => _codeRequested = true);
      _showMessage(
        'Ako račun postoji, kod za reset lozinke je poslan na email.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _newPasswordController.text;
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      _showMessage('Unesite šestocifreni kod iz emaila.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Lozinka mora sadržavati najmanje 6 znakova.');
      return;
    }
    if (password != _confirmPasswordController.text) {
      _showMessage('Lozinke se ne podudaraju.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _apiService.resetForgottenPassword(
        email: _emailController.text.trim(),
        code: code,
        newPassword: password,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        _showMessage(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zaboravljena lozinka')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Reset lozinke',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Zatražite kod na email, pa ga unesite uz novu lozinku. Kod vrijedi 15 minuta.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailController,
            readOnly: _codeRequested,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          if (!_codeRequested)
            FilledButton(
              onPressed: _isLoading ? null : _requestCode,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Pošalji kod'),
            )
          else ...[
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Kod iz emaila',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Nova lozinka',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                labelText: 'Potvrdi novu lozinku',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _resetPassword,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Resetuj lozinku'),
            ),
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () => setState(() {
                      _codeRequested = false;
                      _codeController.clear();
                    }),
              child: const Text('Pošalji novi kod'),
            ),
          ],
        ],
      ),
    );
  }
}
