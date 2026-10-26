import 'package:flutter/material.dart';

import '../models/admin_session.dart';
import '../services/admin_api_client.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.api,
    required this.session,
    required this.onProfileUpdated,
    super.key,
  });

  final AdminApiClient api;
  final AdminSession session;
  final ValueChanged<AdminSession> onProfileUpdated;

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
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmedPassword = false;

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
      final firstName = _firstName.text.trim();
      final lastName = _lastName.text.trim();
      final email = _email.text.trim();
      final result = await widget.api.tryPut('Auth/profile', {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
      });
      if (!result.succeeded) {
        if (mounted) {
          _message(result.message ?? 'Podaci profila nisu sačuvani.');
        }
        return;
      }
      _email.value = TextEditingValue(
        text: email,
        selection: TextSelection.collapsed(offset: email.length),
      );
      widget.onProfileUpdated(widget.session.copyWith(
        firstName: firstName,
        lastName: lastName,
        email: email,
      ));
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
    final theme = Theme.of(context);
    final displayName = '${widget.session.firstName} ${widget.session.lastName}'
        .trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF432A55), Color(0xFF8A5B91)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        foregroundColor: Colors.white,
                        child: Text(
                          widget.session.firstName.isEmpty
                              ? 'A'
                              : widget.session.firstName[0].toUpperCase(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName.isEmpty ? 'Administrator' : displayName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.session.email,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_outlined,
                                size: 17, color: Colors.white),
                            SizedBox(width: 7),
                            Text('Administrator',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SettingsCard(
                  icon: Icons.person_outline,
                  title: 'Lični podaci',
                  subtitle: 'Uredite ime i email koji se prikazuju u aplikaciji.',
                  accent: const Color(0xFF6750A4),
                  child: Form(
                    key: _profileKey,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _textField(_firstName, 'Ime')),
                            const SizedBox(width: 14),
                            Expanded(child: _textField(_lastName, 'Prezime')),
                          ],
                        ),
                        _textField(_email, 'Email', email: true),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _savingProfile ? null : _saveProfile,
                            icon: _savingProfile
                                ? const SizedBox.square(
                                    dimension: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check),
                            label: Text(
                              _savingProfile ? 'Čuvanje…' : 'Sačuvaj izmjene',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SettingsCard(
                  icon: Icons.lock_outline,
                  title: 'Sigurnost naloga',
                  subtitle: 'Redovno koristite jaku i jedinstvenu lozinku.',
                  accent: const Color(0xFF258A78),
                  child: Form(
                    key: _passwordKey,
                    child: Column(
                      children: [
                        _textField(
                          _currentPassword,
                          'Trenutna lozinka',
                          password: true,
                          showPassword: _showCurrentPassword,
                          onTogglePassword: () => setState(() {
                            _showCurrentPassword = !_showCurrentPassword;
                          }),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _textField(
                                _newPassword,
                                'Nova lozinka',
                                password: true,
                                showPassword: _showNewPassword,
                                onTogglePassword: () => setState(() {
                                  _showNewPassword = !_showNewPassword;
                                }),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _textField(
                                _confirmPassword,
                                'Potvrdi novu lozinku',
                                password: true,
                                showPassword: _showConfirmedPassword,
                                onTogglePassword: () => setState(() {
                                  _showConfirmedPassword =
                                      !_showConfirmedPassword;
                                }),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _savingPassword ? null : _changePassword,
                            icon: _savingPassword
                                ? const SizedBox.square(
                                    dimension: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.key_outlined),
                            label: Text(
                              _savingPassword
                                  ? 'Čuvanje…'
                                  : 'Promijeni lozinku',
                            ),
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
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool password = false,
    bool email = false,
    bool showPassword = false,
    VoidCallback? onTogglePassword,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: password && !showPassword,
        keyboardType: email ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(_fieldIcon(label)),
          suffixIcon: password
              ? IconButton(
                  tooltip: showPassword ? 'Sakrij lozinku' : 'Prikaži lozinku',
                  onPressed: onTogglePassword,
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                )
              : null,
        ),
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

  IconData _fieldIcon(String label) => switch (label) {
    'Ime' => Icons.badge_outlined,
    'Prezime' => Icons.badge_outlined,
    'Email' => Icons.alternate_email,
    _ => Icons.lock_outline,
  };
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}
