import 'dart:async';

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
    final current = item['status']?.toString() ?? 'Pending';
    final end = DateTime.tryParse(item['endTime']?.toString() ?? '')?.toLocal();
    if (current != 'Confirmed') {
      _message(current == 'Pending'
          ? 'Termin se može označiti kao završen tek nakon potvrde uplate.'
          : 'Ovaj termin više nema status koji se može promijeniti.');
      return;
    }
    if (end != null && end.isAfter(DateTime.now())) {
      _message('Termin se može označiti kao završen nakon zakazanog završetka.');
      return;
    }
    var status = current;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Promjena statusa termina'),
          content: DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const ['Confirmed', 'Completed']
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
      final result = await widget.api.tryPut('Appointments/${item['id']}', {
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
      if (!result.succeeded) {
        if (mounted) _message(_friendlyStatusError(result.message ?? 'Zahtjev nije uspio.'));
        return;
      }
      await _load();
      if (mounted) _message('Status termina je izmijenjen.');
    } catch (error) {
      if (mounted) _message(_friendlyStatusError(error.toString()));
    }
  }

  String _friendlyStatusError(String message) {
    if (message.contains('Nije dozvoljen prelaz') ||
        message.contains('Pending') && message.contains('Completed')) {
      return 'Termin na čekanju ne može se označiti kao završen. Potvrda se evidentira nakon uspješne uplate.';
    }
    if (message.contains('Termin može potvrditi samo')) {
      return 'Termin se potvrđuje nakon uspješne uplate.';
    }
    if (message.contains('Termin se ne može označiti kao završen prije njegovog završetka')) {
      return 'Termin se može označiti kao završen tek nakon zakazanog završetka.';
    }
    return message.replaceFirst('ApiException: ', '');
  }

  bool _canMarkCompleted(Map<String, dynamic> item) {
    final end = DateTime.tryParse(item['endTime']?.toString() ?? '')?.toLocal();
    return item['status'] == 'Confirmed' &&
        (end == null || !end.isAfter(DateTime.now()));
  }

  Future<void> _createAppointment() => _editAppointment();

  Future<void> _showDetails(Map<String, dynamic> item) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final paid = item['isPaid'] == true;
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Row(children: [
                    CircleAvatar(radius: 25, backgroundColor: scheme.surface,
                      child: Icon(Icons.event_available, color: scheme.primary)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pregled termina', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text('${item['serviceName'] ?? 'Usluga'} · ${item['salonName'] ?? 'Salon'}'),
                      ])),
                    _statusBadge(_statusLabel(item['status']?.toString() ?? '')),
                  ]),
                ),
                Flexible(child: ListView(padding: const EdgeInsets.all(22), children: [
                  _section('Učesnici', Icons.people_outline, [
                    _detail('Korisnik', item['userName']),
                    _detail('Salon', item['salonName']),
                    _detail('Usluga', item['serviceName']),
                    _detail('Zaposlenik', item['employeeName']),
                  ]),
                  const SizedBox(height: 14),
                  _section('Vrijeme i cijena', Icons.schedule, [
                    _detail('Početak', _date(item['startTime'])),
                    _detail('Završetak', _date(item['endTime'])),
                    _detail('Cijena', '${item['price'] ?? 0} KM'),
                  ]),
                  const SizedBox(height: 14),
                  Card(color: paid ? Colors.green.shade50 : Colors.orange.shade50,
                    child: ListTile(
                      leading: Icon(paid ? Icons.check_circle : Icons.pending_actions,
                        color: paid ? Colors.green.shade800 : Colors.orange.shade900),
                      title: Text(paid ? 'Plaćeno' : 'Nije plaćeno',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(paid ? 'Uplata je evidentirana.' : 'Uplata još nije evidentirana.'),
                    )),
                  _detail('Kreirano', _date(item['createdAt'])),
                  if (item['cancelledAt'] != null) ...[
                    const SizedBox(height: 14),
                    _cancellationDetails(item),
                  ],
                  const SizedBox(height: 10),
                  OutlinedButton.icon(onPressed: () => _showStatusHistory(item),
                    icon: const Icon(Icons.history), label: const Text('Historija statusa')),
                ])),
                Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Align(alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zatvori')))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 19), const SizedBox(width: 8), Text(title,
          style: const TextStyle(fontWeight: FontWeight.w700))]),
        const SizedBox(height: 10), ...children,
      ],
    )),
  );

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.52)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_statusIcon(status), size: 16, color: color),
        const SizedBox(width: 7),
        Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Color _statusColor(String status) => switch (status) {
    'Na čekanju' => Colors.orange.shade800,
    'Potvrđen' || 'Potvrđeni' => Colors.blue.shade800,
    'Završen' || 'Završeni' => Colors.green.shade800,
    'Otkazan' || 'Otkazani' => Colors.red.shade800,
    _ => Colors.blueGrey.shade700,
  };

  IconData _statusIcon(String status) => switch (status) {
    'Na čekanju' => Icons.hourglass_top,
    'Potvrđen' || 'Potvrđeni' => Icons.event_available,
    'Završen' || 'Završeni' => Icons.check_circle_outline,
    'Otkazan' || 'Otkazani' => Icons.event_busy,
    _ => Icons.info_outline,
  };

  Widget _cancellationDetails(Map<String, dynamic> item) => Card(
    color: Colors.red.shade50,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: Colors.red.shade200),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.event_busy, color: Colors.red.shade800),
          const SizedBox(width: 9),
          Text('Termin je otkazan', style: TextStyle(
            color: Colors.red.shade900,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          )),
        ]),
        const SizedBox(height: 12),
        _detail('Otkazao/la', _cancelledBy(item)),
        _detail('Datum', _date(item['cancelledAt'])),
        _detail('Razlog', item['cancellationReason'] ?? 'Nije naveden'),
      ]),
    ),
  );

  String _cancelledBy(Map<String, dynamic> item) {
    final name = item['cancelledByName']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    return item['cancelledByUserId'] != null ? 'Administrator' : '—';
  }

  Future<void> _showStatusHistory(Map<String, dynamic> item) async {
    try {
      final history = await widget.api.getList(
        'Appointments/${item['id']}/status-history',
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Historija statusa', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('${item['serviceName'] ?? 'Termin'} · ${_date(item['startTime'])}'),
                  ])),
                ]),
              ),
              Flexible(
                child: history.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.history, size: 42),
                          SizedBox(height: 12),
                          Text('Historija statusa još nije dostupna.'),
                        ]),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(20),
                        itemCount: history.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 9),
                        itemBuilder: (context, index) {
                          final change = history[index];
                          final previous = change['previousStatus']?.toString();
                          final label = _statusLabel(change['newStatus']?.toString() ?? '');
                          final color = _statusColor(label);
                          return Card(
                            color: color.withValues(alpha: 0.13),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                CircleAvatar(
                                  backgroundColor: color.withValues(alpha: 0.2),
                                  child: Icon(_statusIcon(label), color: color),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 7, runSpacing: 6, children: [
                                    if (previous != null) _statusBadge(_statusLabel(previous)),
                                    if (previous != null) Icon(Icons.arrow_forward, size: 16, color: color),
                                    _statusBadge(label),
                                  ]),
                                  const SizedBox(height: 9),
                                  Text('Promijenio/la: ${change['changedByName'] ?? 'Nepoznata osoba'}',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 3),
                                  Text(_date(change['changedAt']), style: Theme.of(context).textTheme.bodySmall),
                                ])),
                              ]),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 20, 14),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Zatvori')),
                ),
              ),
            ]),
          ),
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
        SizedBox(
          width: 125,
          child: Text(label, style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          )),
        ),
        Expanded(child: Text(value?.toString() ?? '—',
          style: const TextStyle(fontWeight: FontWeight.w600))),
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
      var saved = false;
      await showDialog<void>(
        context: context,
        builder: (_) => _NewAppointmentDialog(
          users: references[0],
          salons: references[1],
          employees: references[2],
          services: references[3],
          appointment: appointment,
          onSave: (request) async {
            try {
              final result = appointment == null
                  ? await widget.api.tryPost('Appointments', request)
                  : await widget.api.tryPut('Appointments/${appointment['id']}', {
                      ...request,
                      'id': appointment['id'],
                      'createdAt': appointment['createdAt'],
                    });
              if (!result.succeeded) {
                return _friendlyStatusError(result.message ?? 'Termin nije sačuvan.');
              }
              saved = true;
              return null;
            } catch (error) {
              if (error is TimeoutException) {
                return 'Poslužitelj ne odgovara. Provjerite da li je API pokrenut i pokušajte ponovo.';
              }
              return _friendlyStatusError(error.toString());
            }
          },
        ),
      );
      if (!saved) return;
      await _load();
      if (mounted) {
        _message(appointment == null ? 'Termin je kreiran.' : 'Termin je izmijenjen.');
      }
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }
  Future<void> _cancel(Map<String, dynamic> item) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    backgroundColor: Colors.red.shade100,
                    child: Icon(Icons.event_busy, color: Colors.red.shade800),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Otkazivanje termina', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('${item['serviceName'] ?? 'Termin'} · ${item['salonName'] ?? 'Salon'}'),
                  ])),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.schedule_outlined),
                      const SizedBox(width: 10),
                      Expanded(child: Text(_date(item['startTime']), style: const TextStyle(fontWeight: FontWeight.w600))),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    autofocus: true,
                    maxLength: 500,
                    maxLines: 3,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Razlog otkazivanja *',
                      hintText: 'Ukratko objasnite zašto se termin otkazuje.',
                      helperText: reasonController.text.trim().isEmpty
                          ? 'Razlog je obavezan.'
                          : 'Razlog je unesen.',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 20, 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nazad')),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                    onPressed: reasonController.text.trim().isEmpty
                        ? null
                        : () => Navigator.pop(context, true),
                    icon: const Icon(Icons.event_busy),
                    label: const Text('Potvrdi otkazivanje'),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
    if (confirmed != true) {
      reasonController.dispose();
      return;
    }
    try {
      final result = await widget.api.tryPut('Appointments/${item['id']}/cancel', {
        'reason': reasonController.text.trim(),
      });
      if (!result.succeeded) {
        if (mounted) _message(result.message ?? 'Termin nije otkazan.');
        return;
      }
      await _load();
      if (mounted) _message('Termin je otkazan.');
    } catch (error) {
      if (mounted) _message(error.toString());
    } finally {
      reasonController.dispose();
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
              DataColumn(
                label: SizedBox(
                  width: 88,
                  child: Text('Početak', maxLines: 1, softWrap: false),
                ),
              ),
              DataColumn(label: Text('Cijena')),
              DataColumn(
                label: SizedBox(
                  width: 104,
                  child: Text('Plaćanje', maxLines: 1, softWrap: false),
                ),
              ),
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
                        backgroundColor: item['isPaid'] == true
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        side: BorderSide(
                          color: item['isPaid'] == true
                              ? Colors.green.shade200
                              : Colors.orange.shade200,
                        ),
                        label: Text(
                          item['isPaid'] == true
                              ? 'Plaćeno'
                              : 'Nije plaćeno',
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ),
                    DataCell(
                      _statusBadge(
                        _statusLabel(item['status']?.toString() ?? ''),
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
                              tooltip: _canMarkCompleted(item)
                                  ? 'Označi termin kao završen'
                                  : item['status'] == 'Pending'
                                  ? 'Termin čeka potvrdu uspješne uplate.'
                                  : 'Termin se može završiti nakon zakazanog vremena.',
                              onPressed: _canMarkCompleted(item)
                                  ? () => _changeStatus(item)
                                  : null,
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
    required this.onSave,
    this.appointment,
  });

  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> salons;
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> services;
  final Future<String?> Function(Map<String, dynamic>) onSave;
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
  bool _saving = false;

  bool get _canComplete {
    final end = DateTime.tryParse(
      widget.appointment?['endTime']?.toString() ?? '',
    )?.toLocal();
    return _status == 'Confirmed' &&
        end != null &&
        !end.isAfter(DateTime.now());
  }

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
                  (item) =>
                      '${item['name'] ?? ''} · ${item['price'] ?? 0} KM',
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
                      if (_status == 'Pending')
                        const DropdownMenuItem(
                          value: 'Pending',
                          child: Text('Na čekanju'),
                        ),
                      if (_status == 'Confirmed') ...[
                        const DropdownMenuItem(
                          value: 'Confirmed',
                          child: Text('Potvrđen'),
                        ),
                        if (_canComplete)
                          const DropdownMenuItem(
                            value: 'Completed',
                            child: Text('Završen'),
                          ),
                      ],
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
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check),
          label: Text(widget.appointment == null ? 'Kreiraj termin' : 'Sačuvaj izmjene'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    _formKey.currentState?.validate();
    final problems = <String>[];
    if (_userId == null) problems.add('Odaberite korisnika.');
    if (_salonId == null) problems.add('Odaberite salon.');
    if (_employeeId == null) problems.add('Odaberite zaposlenika.');
    if (_serviceId == null || _service == null) {
      problems.add('Odaberite uslugu.');
    }
    if (problems.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 34),
          title: const Text('Provjerite podatke'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Prije spremanja ispravite sljedeće:'),
              const SizedBox(height: 10),
              for (final problem in problems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('•  '),
                    Expanded(child: Text(problem)),
                  ]),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Razumijem'),
            ),
          ],
        ),
      );
      return;
    }

    final service = _service!;
    final end = _start.add(Duration(
      minutes: (service['durationInMinutes'] as num?)?.toInt() ?? 60,
    ));
    final request = <String, dynamic>{
      'userId': _userId,
      'salonId': _salonId,
      'employeeId': _employeeId,
      'serviceId': _serviceId,
      'startTime': _start.toIso8601String(),
      'endTime': end.toIso8601String(),
      if (widget.appointment != null) 'status': _status,
      'price': service['price'] ?? 0,
    };

    setState(() => _saving = true);
    String? error;
    try {
      error = await widget.onSave(request).timeout(const Duration(seconds: 35));
    } on TimeoutException {
      error = 'Poslužitelj ne odgovara. Provjerite da li je API pokrenut i pokušajte ponovo.';
    } catch (exception) {
      error = exception.toString();
    }
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 34),
          title: const Text('Termin nije sačuvan'),
          content: Text(error!),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('U redu'),
            ),
          ],
        ),
      );
      return;
    }
    Navigator.pop(context);
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
