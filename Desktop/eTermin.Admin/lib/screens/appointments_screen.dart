import 'package:flutter/material.dart';

import '../services/admin_api_client.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({required this.api, super.key});

  final AdminApiClient api;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const _statuses = [
    'Svi',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  String _status = 'Svi';
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.getPagedList(
        'Appointments/admin',
        page: page,
      );
      if (mounted) {
        setState(() {
          _items = result.items;
          _page = result.page;
          _totalPages = result.totalPages;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeStatus(Map<String, dynamic> item) async {
    var status = item['status']?.toString() ?? 'Pending';
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Termin #${item['id']}'),
          content: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: _statuses
                .skip(1)
                .where((value) => value != 'Cancelled')
                .where((value) => value != 'Confirmed' || status == 'Confirmed')
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_statusLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setDialogState(() => status = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Odustani'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, status),
              child: const Text('SaĂ„Ĺ¤uvaj'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || selected == item['status']) return;
    try {
      await widget.api.put('Appointments/${item['id']}', {
        'id': item['id'],
        'userId': item['userId'],
        'salonId': item['salonId'],
        'employeeId': item['employeeId'],
        'serviceId': item['serviceId'],
        'startTime': item['startTime'],
        'endTime': item['endTime'],
        'status': selected,
        'price': item['price'],
        'createdAt': item['createdAt'],
      });
      await _load();
      if (mounted) _message('Status termina je izmijenjen.');
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Future<void> _createAppointment() => _editAppointment();

  Future<void> _showDetails(Map<String, dynamic> item) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalji termina #${item['id']}'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _detail('Korisnik', item['userName']),
                _detail('Salon', item['salonName']),
                _detail('Usluga', item['serviceName']),
                _detail('Zaposlenik', item['employeeName']),
                _detail('PoĂ„Ĺ¤etak', _date(item['startTime'])),
                _detail('ZavrÄąË‡etak', _date(item['endTime'])),
                _detail(
                  'Status',
                  _statusLabel(item['status']?.toString() ?? ''),
                ),
                _detail('Cijena', '${item['price'] ?? 0} KM'),
                _detail('Kreirano', _date(item['createdAt'])),
                if (item['cancelledAt'] != null) ...[
                  _detail('Otkazano', _date(item['cancelledAt'])),
                  _detail('Razlog otkazivanja', item['cancellationReason']),
                  _detail('Otkazao korisnik ID', item['cancelledByUserId']),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () => _showStatusHistory(item),
                    icon: const Icon(Icons.history),
                    label: const Text('Historija statusa'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  Future<void> _showStatusHistory(Map<String, dynamic> item) async {
    try {
      final history = await widget.api.getList(
        'Appointments/${item['id']}/status-history',
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Historija statusa termina #${item['id']}'),
          content: SizedBox(
            width: 480,
            child: history.isEmpty
                ? const Text('Historija statusa nije dostupna.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final change = history[index];
                      final previous = change['previousStatus']?.toString();
                      final newStatus = change['newStatus']?.toString() ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          previous == null
                              ? 'Kreiran: ${_statusLabel(newStatus)}'
                              : '${_statusLabel(previous)} → '
                                    '${_statusLabel(newStatus)}',
                        ),
                        subtitle: Text(
                          '${_date(change['changedAt'])} · '
                          '${change['changedByName'] ?? ''}',
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
        ),
      );
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Widget _detail(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label)),
        Expanded(child: Text(value?.toString() ?? '')),
      ],
    ),
  );

  Future<void> _editAppointment([Map<String, dynamic>? appointment]) async {
    try {
      final references = await Future.wait([
        widget.api.getList('Users'),
        widget.api.getList('Salons'),
        widget.api.getList('Employees'),
        widget.api.getList('Services'),
      ]);
      if (!mounted) return;
      final request = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _NewAppointmentDialog(
          users: references[0],
          salons: references[1],
          employees: references[2],
          services: references[3],
          appointment: appointment,
        ),
      );
      if (request == null) return;
      if (appointment == null) {
        await widget.api.post('Appointments', request);
      } else {
        await widget.api.put('Appointments/${appointment['id']}', {
          ...request,
          'id': appointment['id'],
          'createdAt': appointment['createdAt'],
        });
      }
      await _load();
      if (mounted) {
        _message(
          appointment == null ? 'Termin je kreiran.' : 'Termin je izmijenjen.',
        );
      }
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Future<void> _cancel(Map<String, dynamic> item) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Otkazati termin #${item['id']}?'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: reasonController,
            autofocus: true,
            maxLength: 500,
            decoration: const InputDecoration(labelText: 'Razlog otkazivanja'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim().isNotEmpty),
            child: const Text('Otkazi termin'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      reasonController.dispose();
      return;
    }
    try {
      await widget.api.put('Appointments/${item['id']}/cancel', {
        'reason': reasonController.text.trim(),
      });
      await _load();
      if (mounted) _message('Termin je otkazan.');
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      reasonController.dispose();
    }
  }

  String _statusLabel(String value) => switch (value) {
    'Pending' => 'Na Ă„Ĺ¤ekanju',
    'Confirmed' => 'PotvrĂ„â€en',
    'Completed' => 'ZavrÄąË‡en',
    'Cancelled' => 'Otkazan',
    _ => value,
  };

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (parsed == null) return 'Ă˘â‚¬â€ť';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(parsed.day)}.${two(parsed.month)}.${parsed.year} ${two(parsed.hour)}:${two(parsed.minute)}';
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();
    final visible = _items.where((item) {
      final text =
          '${item['userName']} ${item['salonName']} ${item['employeeName']} ${item['serviceName']}'
              .toLowerCase();
      return (_status == 'Svi' || item['status'] == _status) &&
          (query.isEmpty || text.contains(query));
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
                    labelText: 'PretraÄąÄľi termine',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _search = value),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _statuses
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value == 'Svi' ? value : _statusLabel(value),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'Svi'),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _createAppointment,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj termin'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'OsvjeÄąÄľi',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
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
        OutlinedButton(
          onPressed: _loading || _page <= 1
              ? null
              : () => _load(page: _page - 1),
          child: const Text('Prethodna'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Stranica $_page od $_totalPages'),
        ),
        OutlinedButton(
          onPressed: _loading || _page >= _totalPages
              ? null
              : () => _load(page: _page + 1),
          child: const Text('Sljedeća'),
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
              label: const Text('PokuÄąË‡aj ponovo'),
            ),
          ],
        ),
      );
    }
    if (visible.isEmpty) {
      return Center(
        child: Text(
          _items.isEmpty
              ? 'JoÄąË‡ nema termina u bazi.'
              : 'Nema rezultata za odabrane filtere.',
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
              DataColumn(label: Text('Korisnik')),
              DataColumn(label: Text('Salon / usluga')),
              DataColumn(label: Text('Zaposlenik')),
              DataColumn(label: Text('PoĂ„Ĺ¤etak')),
              DataColumn(label: Text('Cijena')),
              DataColumn(label: Text('PlaĂ„â€ˇanje')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Akcije')),
            ],
            rows: [
              for (final item in visible)
                DataRow(
                  cells: [
                    DataCell(Text(item['userName']?.toString() ?? '')),
                    DataCell(
                      Text(
                        '${item['salonName'] ?? ''}\n${item['serviceName'] ?? ''}',
                      ),
                    ),
                    DataCell(Text(item['employeeName']?.toString() ?? '')),
                    DataCell(Text(_date(item['startTime']))),
                    DataCell(Text('${item['price'] ?? 0} KM')),
                    DataCell(
                      Chip(
                        label: Text(
                          item['isPaid'] == true
                              ? 'PlaĂ„â€ˇeno'
                              : 'Nije plaĂ„â€ˇeno',
                        ),
                      ),
                    ),
                    DataCell(
                      Chip(
                        label: Text(
                          _statusLabel(item['status']?.toString() ?? ''),
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Detalji termina',
                            onPressed: () => _showDetails(item),
                            icon: const Icon(Icons.visibility_outlined),
                          ),
                          if (item['status'] != 'Cancelled' &&
                              item['status'] != 'Completed') ...[
                            IconButton(
                              tooltip: 'Promijeni status',
                              onPressed: () => _changeStatus(item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Uredi podatke termina',
                              onPressed: () => _editAppointment(item),
                              icon: const Icon(Icons.event_note_outlined),
                            ),
                          ],
                          if (item['status'] != 'Cancelled' &&
                              item['status'] != 'Completed' &&
                              item['isPaid'] != true)
                            IconButton(
                              tooltip: 'Otkazati uz razlog',
                              onPressed: () => _cancel(item),
                              icon: const Icon(Icons.event_busy_outlined),
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

class _NewAppointmentDialog extends StatefulWidget {
  const _NewAppointmentDialog({
    required this.users,
    required this.salons,
    required this.employees,
    required this.services,
    this.appointment,
  });

  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> salons;
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> services;
  final Map<String, dynamic>? appointment;

  @override
  State<_NewAppointmentDialog> createState() => _NewAppointmentDialogState();
}

class _NewAppointmentDialogState extends State<_NewAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  int? _userId;
  int? _salonId;
  int? _employeeId;
  int? _serviceId;
  String _status = 'Pending';
  DateTime _start = DateTime.now().add(const Duration(hours: 1));

  @override
  void initState() {
    super.initState();
    final appointment = widget.appointment;
    if (appointment == null) return;
    _userId = (appointment['userId'] as num?)?.toInt();
    _salonId = (appointment['salonId'] as num?)?.toInt();
    _employeeId = (appointment['employeeId'] as num?)?.toInt();
    _serviceId = (appointment['serviceId'] as num?)?.toInt();
    _status = appointment['status']?.toString() ?? 'Pending';
    _start =
        DateTime.tryParse(appointment['startTime']?.toString() ?? '')
            ?.toLocal() ??
        _start;
  }

  List<Map<String, dynamic>> get _employeesForSalon =>
      widget.employees.where((item) => item['salonId'] == _salonId).toList();
  List<Map<String, dynamic>> get _servicesForSalon =>
      widget.services.where((item) => item['salonId'] == _salonId).toList();
  Map<String, dynamic>? get _service {
    for (final item in widget.services) {
      if (item['id'] == _serviceId) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.appointment == null ? 'Dodaj termin' : 'Uredi termin'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dropdown(
                  'Korisnik',
                  _userId,
                  widget.users
                      .where((user) => user['role'] != 'Admin')
                      .toList(),
                  (id) => _userId = id,
                  (item) =>
                      '${item['firstName'] ?? ''} ${item['lastName'] ?? ''} Ă‚Â· ${item['email'] ?? ''}',
                ),
                _dropdown(
                  'Salon',
                  _salonId,
                  widget.salons,
                  (id) => setState(() {
                    _salonId = id;
                    _employeeId = null;
                    _serviceId = null;
                  }),
                  (item) => item['name']?.toString() ?? '',
                ),
                _dropdown(
                  'Zaposlenik',
                  _employeeId,
                  _employeesForSalon,
                  (id) => _employeeId = id,
                  (item) =>
                      '${item['firstName'] ?? ''} ${item['lastName'] ?? ''}',
                ),
                _dropdown(
                  'Usluga',
                  _serviceId,
                  _servicesForSalon,
                  (id) => setState(() => _serviceId = id),
                  (item) =>
                      '${item['name'] ?? ''} Ă‚Â· ${item['price'] ?? 0} KM',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          '${_start.day.toString().padLeft(2, '0')}.${_start.month.toString().padLeft(2, '0')}.${_start.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule),
                        label: Text(
                          '${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.appointment != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: [
                      const DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending'),
                      ),
                      if (_status == 'Confirmed')
                        const DropdownMenuItem(
                          value: 'Confirmed',
                          child: Text('Confirmed'),
                        ),
                      const DropdownMenuItem(
                        value: 'Completed',
                        child: Text('Completed'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _status = value ?? 'Pending'),
                  ),
                ],
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
            if (!_formKey.currentState!.validate() ||
                _userId == null ||
                _salonId == null ||
                _employeeId == null ||
                _serviceId == null) {
              return;
            }
            final service = _service!;
            final end = _start.add(
              Duration(
                minutes: (service['durationInMinutes'] as num?)?.toInt() ?? 60,
              ),
            );
            Navigator.pop(context, {
              'userId': _userId,
              'salonId': _salonId,
              'employeeId': _employeeId,
              'serviceId': _serviceId,
              'startTime': _start.toIso8601String(),
              'endTime': end.toIso8601String(),
              if (widget.appointment != null) 'status': _status,
              'price': service['price'] ?? 0,
            });
          },
          child: Text(
            widget.appointment == null
                ? 'Kreiraj termin'
                : 'SaĂ„Ĺ¤uvaj izmjene',
          ),
        ),
      ],
    );
  }

  Widget _dropdown(
    String label,
    int? selected,
    List<Map<String, dynamic>> entries,
    ValueChanged<int?> onChanged,
    String Function(Map<String, dynamic>) labelFor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        initialValue: entries.any((item) => item['id'] == selected)
            ? selected
            : null,
        decoration: InputDecoration(labelText: label),
        items: entries
            .map(
              (item) => DropdownMenuItem<int>(
                value: (item['id'] as num).toInt(),
                child: Text(labelFor(item), overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Odaberite $label.' : null,
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(
        () => _start = DateTime(
          date.year,
          date.month,
          date.day,
          _start.hour,
          _start.minute,
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time != null) {
      setState(
        () => _start = DateTime(
          _start.year,
          _start.month,
          _start.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }
}
