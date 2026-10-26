import 'package:flutter/material.dart';

import '../services/admin_api_client.dart';

enum CatalogKind { employees, services }

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    required this.api,
    required this.kind,
    this.openCreateOnLoad = false,
    this.onCreateRequestHandled,
    super.key,
  });

  final AdminApiClient api;
  final CatalogKind kind;
  final bool openCreateOnLoad;
  final VoidCallback? onCreateRequestHandled;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _salons = [];
  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;
  String? _dependencyWarning;
  String _search = '';
  int _salonFilter = 0;
  int _page = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  bool _createRequestHandled = false;

  bool get _employees => widget.kind == CatalogKind.employees;
  String get _endpoint => _employees ? 'Employees' : 'Services';
  String get _title => _employees ? 'Zaposlenici' : 'Usluge';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
      _dependencyWarning = null;
    });
    try {
      final itemPage = await widget.api.getPagedList(
        _endpoint,
        page: page,
        queryParameters: {if (_salonFilter > 0) 'salonId': '$_salonFilter'},
      );
      var salons = <Map<String, dynamic>>[];
      var related = <Map<String, dynamic>>[];
      final dependencyErrors = <String>[];
      try {
        salons = await widget.api.getList('Salons');
      } catch (error) {
        dependencyErrors.add('salone: $error');
      }
      try {
        related = await widget.api.getList(
          _employees ? 'Services' : 'ServiceCategories',
        );
      } catch (error) {
        dependencyErrors.add(
          _employees ? 'usluge: $error' : 'kategorije usluga: $error',
        );
      }
      if (!mounted) return;
      setState(() {
        _items = itemPage.items;
        _page = itemPage.page;
        _totalPages = itemPage.totalPages;
        _totalCount = itemPage.totalCount;
        _salons = salons;
        if (_employees) {
          _services = related;
        } else {
          _categories = related;
        }
        _dependencyWarning = dependencyErrors.isEmpty
            ? null
            : 'Pomoćni podaci nisu učitani (${dependencyErrors.join('; ')}). Lista ${_title.toLowerCase()} je učitana, ali dodavanje možda nije dostupno.';
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
      if (mounted && widget.openCreateOnLoad && !_createRequestHandled) {
        _createRequestHandled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.onCreateRequestHandled?.call();
          if (_error == null) _openCreateFromQuickAction();
        });
      }
    }
  }

  void _openCreateFromQuickAction() {
    if (_salons.isEmpty) {
      _message(
        'Prvo dodajte salon, pa zatim ${_employees ? 'zaposlenika' : 'uslugu'}.',
      );
      return;
    }
    if (!_employees && _categories.isEmpty) {
      _message(
        'Prvo dodajte kategoriju usluge u Šifarnici, pa se vratite ovdje.',
      );
      return;
    }
    _edit();
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CatalogEditorDialog(
        kind: widget.kind,
        item: item,
        salons: _salons,
        services: _services,
        categories: _categories,
      ),
    );
    if (result == null) return;
    try {
      final id = item?['id'];
      late final ApiOperationResult saveResult;
      if (id == null) {
        saveResult = await widget.api.tryPost(_endpoint, result);
      } else {
        saveResult = await widget.api.tryPut('$_endpoint/$id', result);
      }
      if (!saveResult.succeeded) {
        if (mounted) {
          _message(saveResult.message ?? 'Podaci nisu sačuvani.');
        }
        return;
      }
      await _load();
      if (mounted) {
        _message(item == null ? 'Zapisano.' : 'Izmjene su sačuvane.');
      }
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final label = _employees
        ? '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}'.trim()
        : item['name']?.toString() ?? 'usluga';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Obrisati ${_employees ? 'zaposlenika' : 'uslugu'}?'),
        content: Text('„$label“ bit će obrisan/a.'),
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
      await widget.api.delete('$_endpoint/${item['id']}');
      await _load();
      if (mounted) _message('Zapis je obrisan.');
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final canAdd = _salons.isNotEmpty && (_employees || _categories.isNotEmpty);
    final addTooltip = _salons.isEmpty
        ? 'Prvo dodajte salon.'
        : (!_employees && _categories.isEmpty)
        ? 'Prvo dodajte kategoriju u Šifarnici → Kategorije usluga.'
        : 'Dodaj ${_employees ? 'zaposlenika' : 'uslugu'}';
    final query = _search.trim().toLowerCase();
    final visible = _items.where((item) {
      final text = _employees
          ? '${item['firstName']} ${item['lastName']} ${item['email']} ${item['position']}'
          : '${item['name']} ${item['description']}';
      final itemSalonId = (item['salonId'] as num?)?.toInt();
      return (_salonFilter == 0 || itemSalonId == _salonFilter) &&
          (query.isEmpty || text.toLowerCase().contains(query));
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Pretraži ${_title.toLowerCase()}',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<int>(
                  initialValue: _salonFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Salon',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('Svi saloni')),
                    for (final salon in _salons)
                      DropdownMenuItem(
                        value: (salon['id'] as num).toInt(),
                        child: Text(
                          salon['name']?.toString() ?? 'Salon',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _salonFilter = value ?? 0);
                    _load(page: 1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Osvježi',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: addTooltip,
                child: FilledButton.icon(
                  onPressed: canAdd ? () => _edit() : null,
                  icon: const Icon(Icons.add),
                  label: Text('Dodaj ${_employees ? 'zaposlenika' : 'uslugu'}'),
                ),
              ),
            ],
          ),
        ),
        if (!_employees && _salons.isNotEmpty && _categories.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Za uslugu su potrebni salon i kategorija.'),
                subtitle: Text(
                  'Dodaj kategoriju u Šifarnici → Kategorije usluga, pa se vrati ovdje. Tada će dugme „Dodaj uslugu“ biti dostupno.',
                ),
              ),
            ),
          ),
        if (_dependencyWarning != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.warning_amber_outlined),
                title: const Text('Neki povezani podaci nisu učitani.'),
                subtitle: Text(_dependencyWarning!),
              ),
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
          onPressed: _loading || _page <= 1
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
          onPressed: _loading || _page >= _totalPages
              ? null
              : () => _load(page: _page + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    ),
  );

  Widget _buildBody(List<Map<String, dynamic>> visible) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
      if (!_employees && _items.isEmpty) {
        final missing = <String>[
          if (_salons.isEmpty) 'Dodaj salon u tabu Saloni.',
          if (_categories.isEmpty) 'Dodaj kategoriju u Šifarnici.',
        ];
        return Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Trenutno nema usluga za prikaz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'API je vratio $_totalCount usluga, ${_salons.length} salona i ${_categories.length} kategorija.'
                    '${missing.isEmpty ? ' Možeš odmah dodati prvu uslugu.' : '\n${missing.join('\n')}'}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return Center(
        child: Text(
          _items.isEmpty
              ? 'Još nema podataka u bazi.'
              : 'Nema rezultata pretrage.',
        ),
      );
    }

    final salonNames = {
      for (final salon in _salons) salon['id']: salon['name']?.toString() ?? '',
    };
    return Card(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: _employees
                ? const [
                    DataColumn(label: Text('Zaposlenik')),
                    DataColumn(label: Text('Salon')),
                    DataColumn(label: Text('Pozicija')),
                    DataColumn(label: Text('Kontakt')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Akcije')),
                  ]
                : const [
                    DataColumn(label: Text('Usluga')),
                    DataColumn(label: Text('Salon')),
                    DataColumn(label: Text('Kategorija')),
                    DataColumn(label: Text('Trajanje')),
                    DataColumn(label: Text('Cijena')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Akcije')),
                  ],
            rows: [
              for (final item in visible)
                DataRow(
                  cells: _employees
                      ? [
                          DataCell(
                            Text(
                              '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}',
                            ),
                          ),
                          DataCell(Text(salonNames[item['salonId']] ?? '')),
                          DataCell(Text(item['position']?.toString() ?? '')),
                          DataCell(
                            Text(
                              '${item['email'] ?? ''}\n${item['phoneNumber'] ?? ''}',
                            ),
                          ),
                          DataCell(
                            _statusChip(
                              item['isActive'] == true,
                              activeLabel: 'Aktivan',
                              inactiveLabel: 'Neaktivan',
                            ),
                          ),
                          _actions(item),
                        ]
                      : [
                          DataCell(Text(item['name']?.toString() ?? '')),
                          DataCell(Text(salonNames[item['salonId']] ?? '')),
                          DataCell(
                            Text(item['serviceCategoryName']?.toString() ?? ''),
                          ),
                          DataCell(
                            Text('${item['durationInMinutes'] ?? 0} min'),
                          ),
                          DataCell(Text('${item['price'] ?? 0} KM')),
                          DataCell(
                            _statusChip(
                              item['isActive'] == true,
                              activeLabel: 'Aktivna',
                              inactiveLabel: 'Neaktivna',
                            ),
                          ),
                          _actions(item),
                        ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  DataCell _actions(Map<String, dynamic> item) => DataCell(
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Uredi',
          onPressed: () => _edit(item),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Obriši',
          onPressed: () => _delete(item),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ),
  );

  Widget _statusChip(
    bool isActive, {
    required String activeLabel,
    required String inactiveLabel,
  }) => Chip(
    avatar: Icon(
      isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
      size: 18,
      color: isActive ? Colors.green.shade800 : Colors.orange.shade900,
    ),
    label: Text(isActive ? activeLabel : inactiveLabel),
    backgroundColor: isActive ? Colors.green.shade50 : Colors.orange.shade50,
    side: BorderSide(
      color: isActive ? Colors.green.shade200 : Colors.orange.shade200,
    ),
    labelStyle: TextStyle(
      color: isActive ? Colors.green.shade900 : Colors.orange.shade900,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _CatalogEditorDialog extends StatefulWidget {
  const _CatalogEditorDialog({
    required this.kind,
    required this.salons,
    required this.services,
    required this.categories,
    this.item,
  });

  final CatalogKind kind;
  final Map<String, dynamic>? item;
  final List<Map<String, dynamic>> salons;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> categories;

  @override
  State<_CatalogEditorDialog> createState() => _CatalogEditorDialogState();
}

class _CatalogEditorDialogState extends State<_CatalogEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  late int? _salonId;
  late int? _categoryId;
  late bool _active;
  late Set<int> _serviceIds;
  final Map<int, List<TimeOfDay>> _workingSchedule = {};
  String? _scheduleError;
  bool get _employees => widget.kind == CatalogKind.employees;

  @override
  void initState() {
    super.initState();
    final item = widget.item ?? {};
    final keys = _employees
        ? ['firstName', 'lastName', 'email', 'phoneNumber', 'position']
        : ['name', 'description', 'durationInMinutes', 'price'];
    _fields = {
      for (final key in keys)
        key: TextEditingController(text: item[key]?.toString() ?? ''),
    };
    _salonId = (item['salonId'] as num?)?.toInt();
    _categoryId = (item['serviceCategoryId'] as num?)?.toInt();
    _active = item['isActive'] as bool? ?? true;
    _serviceIds = ((item['serviceIds'] as List?) ?? [])
        .whereType<num>()
        .map((value) => value.toInt())
        .toSet();
    for (final entry in (item['workingSchedule'] as List?) ?? const []) {
      if (entry is! Map) continue;
      final day = (entry['dayOfWeek'] as num?)?.toInt();
      final start = _parseTime(entry['startTime']);
      final end = _parseTime(entry['endTime']);
      if (day != null && start != null && end != null) {
        _workingSchedule[day] = [start, end];
      }
    }
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
      title: Text(
        '${widget.item == null ? 'Dodaj' : 'Uredi'} ${_employees ? 'zaposlenika' : 'uslugu'}',
      ),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _salonId,
                  decoration: const InputDecoration(labelText: 'Salon *'),
                  items: [
                    for (final salon in widget.salons)
                      DropdownMenuItem<int>(
                        value: (salon['id'] as num).toInt(),
                        child: Text(salon['name']?.toString() ?? ''),
                      ),
                  ],
                  onChanged: (value) => setState(() => _salonId = value),
                  validator: (value) =>
                      value == null ? 'Odaberite salon.' : null,
                ),
                const SizedBox(height: 12),
                if (_employees) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Polja označena zvjezdicom su obavezna. Aktivni zaposlenik mora imati barem jedan radni dan.',
                      ),
                    ),
                  ),
                  _field('firstName', 'Ime', required: true, maxLength: 100),
                  _field('lastName', 'Prezime', required: true, maxLength: 100),
                  _field(
                    'email',
                    'Email',
                    required: true,
                    maxLength: 254,
                    email: true,
                  ),
                  _field(
                    'phoneNumber',
                    'Telefon',
                    required: true,
                    maxLength: 30,
                    phone: true,
                  ),
                  _field(
                    'position',
                    'Pozicija',
                    required: true,
                    maxLength: 100,
                  ),
                  _workingScheduleEditor(),
                  if (widget.services.isNotEmpty)
                    ExpansionTile(
                      title: Text('Usluge zaposlenika (${_serviceIds.length})'),
                      children: [
                        for (final service in widget.services.where(
                          (s) => s['salonId'] == _salonId,
                        ))
                          CheckboxListTile(
                            dense: true,
                            title: Text(service['name']?.toString() ?? ''),
                            value: _serviceIds.contains(
                              (service['id'] as num).toInt(),
                            ),
                            onChanged: (checked) => setState(() {
                              final id = (service['id'] as num).toInt();
                              if (checked == true) {
                                _serviceIds.add(id);
                              } else {
                                _serviceIds.remove(id);
                              }
                            }),
                          ),
                      ],
                    ),
                ] else ...[
                  DropdownButtonFormField<int>(
                    initialValue: _categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategorija usluge',
                    ),
                    items: [
                      for (final category in widget.categories)
                        DropdownMenuItem<int>(
                          value: (category['id'] as num).toInt(),
                          child: Text(category['name']?.toString() ?? ''),
                        ),
                    ],
                    onChanged: (value) => setState(() => _categoryId = value),
                    validator: (value) =>
                        value == null ? 'Odaberite kategoriju.' : null,
                  ),
                  const SizedBox(height: 12),
                  _field('name', 'Naziv usluge', required: true),
                  _field('description', 'Opis', maxLines: 2),
                  _field(
                    'durationInMinutes',
                    'Trajanje u minutama',
                    numeric: true,
                    required: true,
                  ),
                  _field(
                    'price',
                    'Cijena (KM)',
                    numeric: true,
                    decimal: true,
                    required: true,
                  ),
                ],
                SwitchListTile(
                  title: Text(_active ? 'Aktivan zapis' : 'Neaktivan zapis'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
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
            if (_employees && _active && _workingSchedule.isEmpty) {
              setState(
                () => _scheduleError =
                    'Odaberite barem jedan radni dan za aktivnog zaposlenika.',
              );
              return;
            }
            final hasInvalidHours = _workingSchedule.values.any(
              (times) => _minutes(times[1]) <= _minutes(times[0]),
            );
            if (hasInvalidHours) {
              setState(
                () =>
                    _scheduleError = 'Završetak rada mora biti nakon početka.',
              );
              return;
            }
            final body = <String, dynamic>{
              'salonId': _salonId,
              'isActive': _active,
            };
            for (final entry in _fields.entries) {
              if (entry.key == 'durationInMinutes') {
                body[entry.key] = int.tryParse(entry.value.text) ?? 0;
              } else if (entry.key == 'price') {
                body[entry.key] =
                    double.tryParse(entry.value.text.replaceAll(',', '.')) ?? 0;
              } else {
                body[entry.key] = entry.value.text.trim();
              }
            }
            if (_employees) {
              body['serviceIds'] = _serviceIds.toList();
              body['workingSchedule'] = _workingSchedule.entries
                  .map(
                    (entry) => {
                      'dayOfWeek': entry.key,
                      'startTime': _formatTime(entry.value[0]),
                      'endTime': _formatTime(entry.value[1]),
                    },
                  )
                  .toList();
            } else {
              body['serviceCategoryId'] = _categoryId;
            }
            Navigator.pop(context, body);
          },
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }

  Widget _workingScheduleEditor() {
    const days = <int, String>{
      1: 'Ponedjeljak',
      2: 'Utorak',
      3: 'Srijeda',
      4: 'Četvrtak',
      5: 'Petak',
      6: 'Subota',
      0: 'Nedjelja',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Radno vrijeme po danima'),
          ),
        ),
        for (final entry in days.entries)
          Row(
            children: [
              SizedBox(
                width: 132,
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(entry.value),
                  value: _workingSchedule.containsKey(entry.key),
                  onChanged: (enabled) => setState(() {
                    _scheduleError = null;
                    if (enabled == true) {
                      _workingSchedule[entry.key] = [
                        const TimeOfDay(hour: 9, minute: 0),
                        const TimeOfDay(hour: 17, minute: 0),
                      ];
                    } else {
                      _workingSchedule.remove(entry.key);
                    }
                  }),
                ),
              ),
              if (_workingSchedule[entry.key] case final times?) ...[
                TextButton(
                  onPressed: () => _pickScheduleTime(entry.key, 0),
                  child: Text(_formatTime(times[0]).substring(0, 5)),
                ),
                const Text('—'),
                TextButton(
                  onPressed: () => _pickScheduleTime(entry.key, 1),
                  child: Text(_formatTime(times[1]).substring(0, 5)),
                ),
              ] else
                const Text('Neradni dan'),
            ],
          ),
        if (_scheduleError != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _scheduleError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Future<void> _pickScheduleTime(int day, int index) async {
    final times = _workingSchedule[day];
    if (times == null) return;
    final selected = await showTimePicker(
      context: context,
      initialTime: times[index],
    );
    if (selected == null) return;
    setState(() {
      final updated = List<TimeOfDay>.from(times);
      updated[index] = selected;
      _workingSchedule[day] = updated;
      _scheduleError = null;
    });
  }

  TimeOfDay? _parseTime(dynamic value) {
    final parts = value?.toString().split(':') ?? const <String>[];
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

  Widget _field(
    String key,
    String label, {
    bool required = false,
    bool numeric = false,
    bool decimal = false,
    int maxLines = 1,
    int? maxLength,
    bool email = false,
    bool phone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _fields[key],
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: numeric
            ? TextInputType.numberWithOptions(decimal: decimal)
            : TextInputType.text,
        decoration: InputDecoration(labelText: required ? '$label *' : label),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Ovo polje je obavezno.';
          }
          final text = value?.trim() ?? '';
          if (maxLength != null && text.length > maxLength) {
            return '$label može imati najviše $maxLength znakova.';
          }
          if (email &&
              text.isNotEmpty &&
              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
            return 'Unesite email u obliku ime@domena.ba.';
          }
          if (phone && text.isNotEmpty) {
            final normalized = text.replaceAll(RegExp(r'[\s()./-]'), '');
            if (!RegExp(r'^(?:0\d{7,9}|\+387\d{7,9})$').hasMatch(normalized)) {
              return 'Primjer ispravnog broja: 061 123 456.';
            }
          }
          if (numeric && value != null) {
            final parsed = decimal
                ? double.tryParse(value.replaceAll(',', '.'))
                : int.tryParse(value);
            if (parsed == null) return 'Unesite ispravnu brojčanu vrijednost.';
          }
          return null;
        },
      ),
    );
  }
}
