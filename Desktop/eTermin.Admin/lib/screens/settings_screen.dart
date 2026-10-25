import 'package:flutter/material.dart';

import '../models/admin_session.dart';
import '../services/admin_api_client.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.api, required this.session, super.key});

  final AdminApiClient api;
  final AdminSession session;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _profileKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();
  late final _firstName = TextEditingController(text: widget.session.firstName);
  late final _lastName = TextEditingController(text: widget.session.lastName);
  late final _email = TextEditingController(text: widget.session.email);
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _savingProfile = false;
  bool _savingPassword = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileKey.currentState!.validate()) return;
    setState(() => _savingProfile = true);
    try {
      await widget.api.put('Auth/profile', {
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim(),
      });
      if (mounted) _message('Podaci profila su sačuvani.');
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_passwordKey.currentState!.validate()) return;
    setState(() => _savingPassword = true);
    try {
      await widget.api.put('Auth/change-password', {
        'currentPassword': _currentPassword.text,
        'newPassword': _newPassword.text,
      });
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (mounted) _message('Lozinka je promijenjena.');
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _profileKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    _textField(_firstName, 'Ime'),
                    _textField(_lastName, 'Prezime'),
                    _textField(_email, 'Email', email: true),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _savingProfile ? null : _saveProfile,
                      child: Text(
                        _savingProfile ? 'Spremanje…' : 'Sačuvaj profil',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _passwordKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Promjena lozinke',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 20),
                    _textField(
                      _currentPassword,
                      'Trenutna lozinka',
                      password: true,
                    ),
                    _textField(_newPassword, 'Nova lozinka', password: true),
                    _textField(
                      _confirmPassword,
                      'Potvrdi novu lozinku',
                      password: true,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _savingPassword ? null : _changePassword,
                      child: Text(
                        _savingPassword ? 'Spremanje…' : 'Promijeni lozinku',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool password = false,
    bool email = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: password,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Ovo polje je obavezno.';
          }
          if (email && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
            return 'Unesite ispravnu email adresu.';
          }
          if (label == 'Nova lozinka' && value.length < 6) {
            return 'Lozinka mora imati najmanje 6 znakova.';
          }
          if (label == 'Potvrdi novu lozinku' && value != _newPassword.text) {
            return 'Lozinke se ne podudaraju.';
          }
          if (label == 'Nova lozinka' && value == _currentPassword.text) {
            return 'Nova lozinka mora biti drugačija.';
          }
          return null;
        },
      ),
    );
  }
}
