import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../services/admin_api_client.dart';

class SalonsScreen extends StatefulWidget {
  const SalonsScreen({required this.api, super.key});

  final AdminApiClient api;

  @override
  State<SalonsScreen> createState() => _SalonsScreenState();
}

class _SalonsScreenState extends State<SalonsScreen> {
  List<Salon> _salons = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await widget.api.getList('Salons');
      if (mounted) setState(() => _salons = rows.map(Salon.fromJson).toList());
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editSalon([Salon? salon]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _SalonFormDialog(salon: salon),
    );
    if (result == null) return;
    try {
      if (salon == null) {
        await widget.api.post('Salons', result);
      } else {
        await widget.api.put('Salons/${salon.id}', result);
      }
      await _load();
      if (mounted) {
        _showMessage(
          salon == null ? 'Salon je dodan.' : 'Salon je izmijenjen.',
        );
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  Future<void> _deleteSalon(Salon salon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obrisati salon?'),
        content: Text('Salon „${salon.name}“ bit će obrisan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.delete('Salons/${salon.id}');
      await _load();
      if (mounted) _showMessage('Salon je obrisan.');
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();
    final visible = _salons.where((salon) {
      return query.isEmpty ||
          salon.name.toLowerCase().contains(query) ||
          salon.city.toLowerCase().contains(query) ||
          salon.email.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Pretraži salone',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Osvježi',
                onPressed: _isLoading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _editSalon(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj salon'),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(visible)),
      ],
    );
  }

  Widget _buildBody(List<Salon> visible) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }
    if (visible.isEmpty) {
      return Center(
        child: Text(
          _salons.isEmpty
              ? 'Još nema salona u bazi.'
              : 'Nema rezultata pretrage.',
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Salon')),
              DataColumn(label: Text('Grad')),
              DataColumn(label: Text('Adresa')),
              DataColumn(label: Text('Kontakt')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Akcije')),
            ],
            rows: [
              for (final salon in visible)
                DataRow(
                  cells: [
                    DataCell(Text(salon.name)),
                    DataCell(Text(salon.city)),
                    DataCell(Text(salon.address)),
                    DataCell(Text('${salon.email}\n${salon.phoneNumber}')),
                    DataCell(
                      Chip(
                        label: Text(salon.isActive ? 'Aktivan' : 'Neaktivan'),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Uredi',
                            onPressed: () => _editSalon(salon),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Obriši',
                            onPressed: () => _deleteSalon(salon),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalonFormDialog extends StatefulWidget {
  const _SalonFormDialog({this.salon});

  final Salon? salon;

  @override
  State<_SalonFormDialog> createState() => _SalonFormDialogState();
}

class _SalonFormDialogState extends State<_SalonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final salon = widget.salon;
    _fields = {
      'name': TextEditingController(text: salon?.name ?? ''),
      'description': TextEditingController(text: salon?.description ?? ''),
      'address': TextEditingController(text: salon?.address ?? ''),
      'city': TextEditingController(text: salon?.city ?? ''),
      'phoneNumber': TextEditingController(text: salon?.phoneNumber ?? ''),
      'email': TextEditingController(text: salon?.email ?? ''),
      'imageUrl': TextEditingController(text: salon?.imageUrl ?? ''),
    };
    _isActive = salon?.isActive ?? true;
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.salon == null ? 'Dodaj salon' : 'Uredi salon'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('name', 'Naziv', required: true),
                _field('description', 'Opis', maxLines: 2),
                _field('address', 'Adresa'),
                _field('city', 'Grad'),
                _field('phoneNumber', 'Telefon'),
                _field('email', 'Email'),
                _field('imageUrl', 'URL slike'),
                SwitchListTile(
                  title: const Text('Aktivan'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              for (final entry in _fields.entries)
                entry.key: entry.value.text.trim(),
              'isActive': _isActive,
            });
          },
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }

  Widget _field(
    String key,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _fields[key],
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Ovo polje je obavezno.'
                  : null
            : null,
      ),
    );
  }
}
