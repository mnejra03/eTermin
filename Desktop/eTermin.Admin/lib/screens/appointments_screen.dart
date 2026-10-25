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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.api.getList('Appointments/admin');
      if (mounted) setState(() => _items = items);
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
              child: const Text('Sačuvaj'),
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
                _detail('Početak', _date(item['startTime'])),
                _detail('Završetak', _date(item['endTime'])),
                _detail(
                  'Status',
                  _statusLabel(item['status']?.toString() ?? ''),
                ),
                _detail('Cijena', '${item['price'] ?? 0} KM'),
                _detail('Kreirano', _date(item['createdAt'])),
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

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obrisati termin?'),
        content: Text(
          'Termin #${item['id']} za ${item['userName']} bit će obrisan.',
        ),
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
      await widget.api.delete('Appointments/${item['id']}');
      await _load();
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  String _statusLabel(String value) => switch (value) {
    'Pending' => 'Na čekanju',
    'Confirmed' => 'Potvrđen',
    'Completed' => 'Završen',
    'Cancelled' => 'Otkazan',
    _ => value,
  };

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (parsed == null) return '—';
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
                    labelText: 'Pretraži termine',
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
                tooltip: 'Osvježi',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(visible)),
      ],
    );
  }

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
      return Center(
        child: Text(
          _items.isEmpty
              ? 'Još nema termina u bazi.'
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
              DataColumn(label: Text('Početak')),
              DataColumn(label: Text('Cijena')),
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
                          IconButton(
                            tooltip: 'Obriši',
                            onPressed: () => _delete(item),
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
                      '${item['firstName'] ?? ''} ${item['lastName'] ?? ''} · ${item['email'] ?? ''}',
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
                  (item) => '${item['name'] ?? ''} · ${item['price'] ?? 0} KM',
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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items:
                      const ['Pending', 'Confirmed', 'Completed', 'Cancelled']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'Pending'),
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
              'status': _status,
              'price': service['price'] ?? 0,
            });
          },
          child: Text(
            widget.appointment == null ? 'Kreiraj termin' : 'Sačuvaj izmjene',
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
