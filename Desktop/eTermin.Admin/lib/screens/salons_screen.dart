import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../models/salon.dart';
import '../services/admin_api_client.dart';
import 'salon_details_dialog.dart';

class SalonsScreen extends StatefulWidget {
  const SalonsScreen({
    required this.api,
    this.openCreateOnLoad = false,
    this.onCreateRequestHandled,
    super.key,
  });

  final AdminApiClient api;
  final bool openCreateOnLoad;
  final VoidCallback? onCreateRequestHandled;

  @override
  State<SalonsScreen> createState() => _SalonsScreenState();
}

class _SalonsScreenState extends State<SalonsScreen> {
  List<Salon> _salons = [];
  List<Map<String, dynamic>> _cities = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';
  int _page = 1;
  int _totalPages = 1;
  int _totalSalonCount = 0;
  int _activeSalonCount = 0;
  int _inactiveSalonCount = 0;
  bool _createRequestHandled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.getPagedList('Salons', page: page),
        widget.api.getList('Cities'),
        widget.api.getList('Salons'),
      ]);
      if (mounted) {
        setState(() {
          final salonPage = results[0] as ApiPage<Map<String, dynamic>>;
          final allSalons = results[2] as List<Map<String, dynamic>>;
          _salons = salonPage.items.map(Salon.fromJson).toList();
          _page = salonPage.page;
          _totalPages = salonPage.totalPages;
          _cities = results[1] as List<Map<String, dynamic>>;
          _totalSalonCount = allSalons.length;
          _activeSalonCount = allSalons
              .where((salon) => salon['isActive'] == true)
              .length;
          _inactiveSalonCount = _totalSalonCount - _activeSalonCount;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
      if (mounted && widget.openCreateOnLoad && !_createRequestHandled) {
        _createRequestHandled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onCreateRequestHandled?.call();
          if (_cities.isEmpty) {
            _showMessage('Prvo dodajte grad u Šifarnici, pa zatim salon.');
          } else {
            _editSalon();
          }
        });
      }
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
        final saveResult = await widget.api.tryPost('Salons', result.body);
        if (!saveResult.succeeded) {
          if (mounted) {
            _showMessage(saveResult.message ?? 'Salon nije moguće sačuvati.');
          }
          return;
        }
        final createdId = saveResult.data?['id'];
        if (createdId is! num) {
          if (mounted) _showMessage('API nije vratio ID novog salona.');
          return;
        }
        salonId = createdId.toInt();
      } else {
        salonId = salon.id;
        final saveResult = await widget.api.tryPut(
          'Salons/$salonId',
          result.body,
        );
        if (!saveResult.succeeded) {
          if (mounted) {
            _showMessage(saveResult.message ?? 'Salon nije moguće sačuvati.');
          }
          return;
        }
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
      builder: (_) => SalonDetailsDialog(salon: salon, api: widget.api),
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
      final result = await widget.api.tryDelete('Salons/${salon.id}');
      if (!result.succeeded) {
        if (mounted) {
          _showMessage(result.message ?? 'Salon nije moguće obrisati.');
        }
        return;
      }
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: _SalonCountCard(
                  title: 'Svi saloni',
                  count: _totalSalonCount,
                  icon: Icons.storefront_outlined,
                  color: const Color(0xFF6750A4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SalonCountCard(
                  title: 'Aktivni',
                  count: _activeSalonCount,
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF258A78),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SalonCountCard(
                  title: 'Neaktivni',
                  count: _inactiveSalonCount,
                  icon: Icons.pause_circle_outline,
                  color: const Color(0xFFB46B35),
                ),
              ),
            ],
          ),
        ),
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
        _buildPager(),
      ],
    );
  }

  Widget _buildPager() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Prethodna stranica',
          onPressed: _isLoading || _page <= 1
              ? null
              : () => _load(page: _page - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Stranica $_page od $_totalPages'),
        ),
        IconButton(
          tooltip: 'Sljedeća stranica',
          onPressed: _isLoading || _page >= _totalPages
              ? null
              : () => _load(page: _page + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );

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
                        avatar: Icon(
                          salon.isActive
                              ? Icons.check_circle_outline
                              : Icons.pause_circle_outline,
                          size: 18,
                          color: salon.isActive
                              ? Colors.green.shade800
                              : Colors.orange.shade900,
                        ),
                        label: Text(salon.isActive ? 'Aktivan' : 'Neaktivan'),
                        backgroundColor: salon.isActive
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        side: BorderSide(
                          color: salon.isActive
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                        labelStyle: TextStyle(
                          color: salon.isActive
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
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

class _SalonCountCard extends StatelessWidget {
  const _SalonCountCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: 0.22)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
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
                _field('name', 'Naziv', required: true, maxLength: 100),
                _field('description', 'Opis', maxLines: 2, maxLength: 500),
                _field(
                  'address',
                  'Adresa',
                  required: true,
                  maxLength: 200,
                  address: true,
                ),
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
                _field(
                  'phoneNumber',
                  'Telefon',
                  required: true,
                  maxLength: 30,
                  phone: true,
                ),
                _field(
                  'email',
                  'Email',
                  required: true,
                  maxLength: 254,
                  email: true,
                ),
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
    int? maxLength,
    bool email = false,
    bool phone = false,
    bool address = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _fields[key],
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (required && text.isEmpty) {
            return 'Polje "$label" je obavezno.';
          }
          if (maxLength != null && text.length > maxLength) {
            return '$label može imati najviše $maxLength znakova.';
          }
          if (email &&
              text.isNotEmpty &&
              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
            return 'Unesite ispravnu email adresu.';
          }
          if (phone && text.isNotEmpty) {
            final normalized = text.replaceAll(RegExp(r'[\s()./-]'), '');
            if (!RegExp(r'^(?:0\d{7,9}|\+387\d{7,9})$').hasMatch(normalized)) {
              return 'Unesite broj kao 061 123 456 ili +387 61 123 456.';
            }
          }
          if (address &&
              text.isNotEmpty &&
              (text.length < 5 ||
                  !RegExp(r'[A-Za-zČĆŽŠĐčćžšđ]').hasMatch(text) ||
                  !RegExp(r'\d').hasMatch(text))) {
            return 'Unesite ulicu i broj, npr. Maršala Tita 25.';
          }
          return null;
        },
      ),
    );
  }
}

class _SalonFormResult {
  const _SalonFormResult({required this.body, required this.images});

  final Map<String, dynamic> body;
  final List<PlatformFile> images;
}
