import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

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
  List<Map<String, dynamic>> _cities = [];
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
      final results = await Future.wait([
        widget.api.getList('Salons'),
        widget.api.getList('Cities'),
      ]);
      if (mounted) {
        setState(() {
          _salons = results[0].map(Salon.fromJson).toList();
          _cities = results[1];
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editSalon([Salon? salon]) async {
    final result = await showDialog<_SalonFormResult>(
      context: context,
      builder: (_) => _SalonFormDialog(salon: salon, cities: _cities),
    );
    if (result == null) return;
    try {
      late final int salonId;
      if (salon == null) {
        final created = await widget.api.post('Salons', result.body);
        salonId = (created['id'] as num).toInt();
      } else {
        salonId = salon.id;
        await widget.api.put('Salons/$salonId', result.body);
      }
      for (var index = 0; index < result.images.length; index++) {
        final image = result.images[index];
        final bytes = await image.readAsBytes();
        await widget.api.uploadSalonImage(
          salonId: salonId,
          bytes: bytes,
          fileName: image.name,
          sortOrder: index,
        );
      }
      await _load();
      if (mounted) {
        _showMessage(
          result.images.isEmpty
              ? (salon == null ? 'Salon je dodan.' : 'Salon je izmijenjen.')
              : 'Salon i slike su sačuvani.',
        );
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  Future<void> _showSalonDetails(Salon salon) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _SalonDetailsDialog(salon: salon, api: widget.api),
    );
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
          salon.cityName.toLowerCase().contains(query) ||
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
                onPressed: _cities.isEmpty ? null : () => _editSalon(),
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
              DataColumn(label: Text('Zaposlenici')),
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
                    DataCell(Text(salon.cityName)),
                    DataCell(Text('${salon.employeeCount}')),
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
                            tooltip: 'Detalji salona',
                            onPressed: () => _showSalonDetails(salon),
                            icon: const Icon(Icons.info_outline),
                          ),
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
  const _SalonFormDialog({required this.cities, this.salon});

  final Salon? salon;
  final List<Map<String, dynamic>> cities;

  @override
  State<_SalonFormDialog> createState() => _SalonFormDialogState();
}

class _SalonFormDialogState extends State<_SalonFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late bool _isActive;
  late int? _cityId;
  final List<PlatformFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    final salon = widget.salon;
    _fields = {
      'name': TextEditingController(text: salon?.name ?? ''),
      'description': TextEditingController(text: salon?.description ?? ''),
      'address': TextEditingController(text: salon?.address ?? ''),
      'phoneNumber': TextEditingController(text: salon?.phoneNumber ?? ''),
      'email': TextEditingController(text: salon?.email ?? ''),
    };
    _imageControllers = [
      for (final image in salon?.images ?? const <Map<String, dynamic>>[])
        TextEditingController(text: image['imageUrl']?.toString() ?? ''),
    ];
    if (_imageControllers.isEmpty && (salon?.imageUrl.isNotEmpty ?? false)) {
      _imageControllers.add(TextEditingController(text: salon!.imageUrl));
    }
    _isActive = salon?.isActive ?? true;
    _cityId = salon?.cityId;
  }

  late final List<TextEditingController> _imageControllers;

  Future<void> _pickImages() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result.isEmpty || !mounted) return;
    setState(() => _selectedImages.addAll(result));
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    for (final image in _imageControllers) {
      image.dispose();
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
                DropdownButtonFormField<int>(
                  initialValue: _cityId,
                  decoration: const InputDecoration(labelText: 'Grad'),
                  items: [
                    for (final city in widget.cities)
                      DropdownMenuItem<int>(
                        value: (city['id'] as num).toInt(),
                        child: Text(city['name']?.toString() ?? ''),
                      ),
                  ],
                  onChanged: (value) => setState(() => _cityId = value),
                  validator: (value) =>
                      value == null ? 'Odaberite grad.' : null,
                ),
                const SizedBox(height: 12),
                _field('phoneNumber', 'Telefon'),
                _field('email', 'Email'),
                _imagesEditor(),
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
            final images = _imageControllers
                .map((controller) => controller.text.trim())
                .where((value) => value.isNotEmpty)
                .toList();
            Navigator.pop(
              context,
              _SalonFormResult(
                body: {
                  for (final entry in _fields.entries)
                    entry.key: entry.value.text.trim(),
                  'cityId': _cityId,
                  'imageUrl': images.isEmpty ? '' : images.first,
                  'images': [
                    for (var i = 0; i < images.length; i++)
                      {'imageUrl': images[i], 'sortOrder': i},
                  ],
                  'isActive': _isActive,
                },
                images: List<PlatformFile>.unmodifiable(_selectedImages),
              ),
            );
          },
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }

  Widget _imagesEditor() => Column(
    children: [
      for (var index = 0; index < _imageControllers.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _imageControllers[index],
                  decoration: InputDecoration(
                    labelText: 'URL slike ${index + 1}',
                  ),
                  validator: (value) {
                    if (value != null &&
                        value.trim().isNotEmpty &&
                        value.trim().length > 1000) {
                      return 'URL slike može imati najviše 1000 znakova.';
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                tooltip: 'Ukloni sliku',
                onPressed: () =>
                    setState(() => _imageControllers.removeAt(index).dispose()),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      if (_selectedImages.isNotEmpty)
        Wrap(
          spacing: 8,
          children: [
            for (var index = 0; index < _selectedImages.length; index++)
              InputChip(
                avatar: const Icon(Icons.image_outlined, size: 18),
                label: Text(_selectedImages[index].name),
                onDeleted: () =>
                    setState(() => _selectedImages.removeAt(index)),
              ),
          ],
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.upload_file),
              label: const Text('Odaberi slike s diska'),
            ),
            TextButton.icon(
              onPressed: () => setState(
                () => _imageControllers.add(TextEditingController()),
              ),
              icon: const Icon(Icons.add_link),
              label: const Text('Dodaj URL slike'),
            ),
          ],
        ),
      ),
    ],
  );

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

class _SalonFormResult {
  const _SalonFormResult({required this.body, required this.images});

  final Map<String, dynamic> body;
  final List<PlatformFile> images;
}

class _SalonDetailsDialog extends StatefulWidget {
  const _SalonDetailsDialog({required this.salon, required this.api});

  final Salon salon;
  final AdminApiClient api;

  @override
  State<_SalonDetailsDialog> createState() => _SalonDetailsDialogState();
}

class _SalonDetailsDialogState extends State<_SalonDetailsDialog> {
  late final Future<Map<String, dynamic>> _statistics;

  @override
  void initState() {
    super.initState();
    final query = Uri(
      queryParameters: {
        'salonId': '${widget.salon.id}',
        'status': 'All statuses',
      },
    ).query;
    _statistics = widget.api.getMap('Statistics/dashboard?$query');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.salon.name),
      content: SizedBox(
        width: 540,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _statistics,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Statistika nije dostupna: ${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!;
            final services = (data['reservationsByService'] as List? ?? [])
                .whereType<Map<String, dynamic>>()
                .toList();
            final popularUser = data['mostActiveUser']?.toString();
            final appointmentCount =
                (data['totalAppointments'] as num?)?.toInt() ?? 0;
            final userCount = (data['totalUsers'] as num?)?.toInt() ?? 0;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${widget.salon.cityName} • ${widget.salon.address}'),
                  Text(
                    'Kontakt: ${widget.salon.phoneNumber} • ${widget.salon.email}',
                  ),
                  const SizedBox(height: 20),
                  Text('Broj zaposlenika: ${widget.salon.employeeCount}'),
                  Text('Ukupno rezervacija: $appointmentCount'),
                  Text('Korisnici s rezervacijom: $userCount'),
                  Text(
                    'Najangažovaniji korisnik: '
                    '${popularUser == null || popularUser.isEmpty ? 'Nema podataka' : '$popularUser (${data['mostActiveUserCount'] ?? 0} rezervacija)'}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Najpopularnije usluge',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (services.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Još nema rezervacija za ovaj salon.'),
                    )
                  else
                    for (final service in services.take(5))
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(service['serviceName']?.toString() ?? ''),
                        trailing: Text('${service['count'] ?? 0} rezervacija'),
                      ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zatvori'),
        ),
      ],
    );
  }
}
