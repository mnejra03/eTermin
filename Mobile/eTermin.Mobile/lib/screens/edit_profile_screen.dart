import 'package:flutter/material.dart';

import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    required this.firstName,
    required this.lastName,
    required this.email,
    super.key,
  });

  final String firstName;
  final String lastName;
  final String email;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    try {
      await _apiService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
      );
      if (mounted) {
        Navigator.pop(context, {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Izmjena profila')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ime'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Unesite ime.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Prezime'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Unesite prezime.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                  return 'Unesite ispravnu email adresu.';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sačuvaj izmjene'),
            ),
          ],
        ),
      ),
    );
  }
}
