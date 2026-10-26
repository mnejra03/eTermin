import 'dart:io';

import 'package:flutter/material.dart';

import '../models/admin_session.dart';
import '../services/auth_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    required this.authService,
    required this.onAuthenticated,
    super.key,
  });

  final AuthService authService;
  final ValueChanged<AdminSession> onAuthenticated;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      _emailController.value = TextEditingValue(
        text: email,
        selection: TextSelection.collapsed(offset: email.length),
      );
      final result = await widget.authService.login(
        email: email,
        password: _passwordController.text,
      );
      if (!result.succeeded) {
        if (mounted) {
          setState(() => _error = result.message ?? 'Prijava nije uspjela.');
        }
        return;
      }
      if (mounted) widget.onAuthenticated(result.session!);
    } on SocketException {
      if (mounted) {
        setState(
          () => _error = 'Nije moguće povezati se s API-jem. Provjerite da li je pokrenut.',
        );
      }
    } on HttpException catch (error) {
      if (mounted) setState(() => _error = 'Greška pri povezivanju: $error');
    } on FormatException {
      if (mounted) setState(() => _error = 'API je vratio neispravan odgovor.');
    } catch (error) {
      if (mounted) setState(() => _error = 'Greška pri prijavi: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  margin: const EdgeInsets.all(24),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(36),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.spa_outlined,
                            size: 48,
                            color: colors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'eTermin administracija',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Prijavite se administratorskim računom',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _emailController,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.username],
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Unesite email adresu.'
                                : null,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Lozinka',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Prikaži lozinku'
                                    : 'Sakrij lozinku',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Unesite lozinku.'
                                : null,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: colors.error),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: _isSubmitting
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Prijavi se'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
