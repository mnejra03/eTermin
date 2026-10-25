import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../services/admin_api_client.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({required this.api, super.key});

  final AdminApiClient api;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  static const _periods = ['Danas', 'Sedmični', 'Mjesečni'];
  static const _statuses = [
    'Svi statusi',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];
  String _period = 'Danas';
  String _status = 'Svi statusi';
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

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
    final query = _queryParameters();
    try {
      final data = await widget.api.getMap(
        'Statistics/dashboard?${Uri(queryParameters: query).query}',
      );
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, String> _queryParameters() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    late DateTime from;
    late DateTime to;
    switch (_period) {
      case 'Sedmi\u010Dni':
        from = today.subtract(Duration(days: today.weekday - 1));
        to = from.add(const Duration(days: 7));
        break;
      case 'Mjese\u010Dni':
        from = DateTime(today.year, today.month);
        to = DateTime(today.year, today.month + 1);
        break;
      default:
        from = today;
        to = today.add(const Duration(days: 1));
        break;
    }
    return <String, String>{
      'from': _date(from),
      'to': _date(to),
      if (_status != 'Svi statusi') 'status': _status,
    };
  }

  Future<void> _export(String format) async {
    try {
      final query = Uri(queryParameters: _queryParameters()).query;
      final extension = format == 'excel' ? 'xlsx' : 'pdf';
      final filePath = await widget.api.downloadToDownloads(
        'Statistics/export/$format?$query',
        'etermin-izvjestaj-${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izvještaj je sačuvan: $filePath')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  String _pdfReportPath(String report) {
    final query = Uri(queryParameters: _queryParameters()).query;
    final endpoint = report == 'salon-revenue'
        ? 'Statistics/export/salon-revenue/pdf'
        : 'Statistics/export/pdf';
    return '$endpoint?$query';
  }

  Future<void> _savePdf(String report) async {
    final isSalonRevenue = report == 'salon-revenue';
    try {
      final filePath = await widget.api.downloadToDownloads(
        _pdfReportPath(report),
        isSalonRevenue
            ? 'etermin-prihod-po-salonima-${DateTime.now().millisecondsSinceEpoch}.pdf'
            : 'etermin-statistika-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF izvještaj je sačuvan: $filePath')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _printPdf(String report) async {
    try {
      final bytes = await widget.api.downloadBytes(_pdfReportPath(report));
      await Printing.layoutPdf(
        onLayout: (_) async => Uint8List.fromList(bytes),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  String _date(DateTime value) => value.toIso8601String().substring(0, 10);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _period,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: _periods
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _period = value);
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status termina',
                  ),
                  items: _statuses
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value == 'Svi statusi'
                                ? value
                                : _statusLabel(value),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _status = value);
                    _load();
                  },
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Sačuvaj statistički PDF izvještaj',
                onPressed: () => _savePdf('statistics'),
                icon: const Icon(Icons.picture_as_pdf_outlined),
              ),
              IconButton(
                tooltip: 'Ispiši statistički PDF izvještaj',
                onPressed: () => _printPdf('statistics'),
                icon: const Icon(Icons.print_outlined),
              ),
              IconButton(
                tooltip: 'Sačuvaj PDF: prihod po salonima',
                onPressed: () => _savePdf('salon-revenue'),
                icon: const Icon(Icons.request_quote_outlined),
              ),
              IconButton(
                tooltip: 'Ispiši PDF: prihod po salonima',
                onPressed: () => _printPdf('salon-revenue'),
                icon: const Icon(Icons.print),
              ),
              IconButton(
                tooltip: 'Preuzmi Excel izvještaj',
                onPressed: () => _export('excel'),
                icon: const Icon(Icons.table_view_outlined),
              ),
              IconButton(
                tooltip: 'Osvježi',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(child: _buildData(context)),
      ],
    );
  }

  Widget _buildData(BuildContext context) {
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
    final data = _data ?? {};
    final byDay = (data['reservationsByDay'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final byService = (data['reservationsByService'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final byStatus = (data['reservationsByStatus'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final maxDay = byDay.fold<int>(
      1,
      (max, item) => (item['count'] as num? ?? 0).toInt() > max
          ? (item['count'] as num).toInt()
          : max,
    );
    final maxService = byService.fold<int>(
      1,
      (max, item) => (item['count'] as num? ?? 0).toInt() > max
          ? (item['count'] as num).toInt()
          : max,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _Metric(
                title: 'Rezervacije',
                value: '${data['totalAppointments'] ?? 0}',
                icon: Icons.calendar_month_outlined,
              ),
              _Metric(
                title: 'Prihod',
                value:
                    '${((data['totalRevenue'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)} KM',
                icon: Icons.payments_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ChartCard(
            title: 'Rezervacije po danima',
            child: byDay.isEmpty
                ? const Text('Nema podataka za odabrani period.')
                : Column(
                    children: [
                      for (final item in byDay)
                        _BarRow(
                          label: _shortDate(item['date']?.toString()),
                          value: (item['count'] as num? ?? 0).toInt(),
                          max: maxDay,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ChartCard(
                  title: 'Najtraženije usluge',
                  child: byService.isEmpty
                      ? const Text('Nema podataka.')
                      : Column(
                          children: [
                            for (final item in byService)
                              _BarRow(
                                label: item['serviceName']?.toString() ?? '',
                                value: (item['count'] as num? ?? 0).toInt(),
                                max: maxService,
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ChartCard(
                  title: 'Statusi termina',
                  child: byStatus.isEmpty
                      ? const Text('Nema podataka.')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final item in byStatus)
                              Chip(
                                label: Text(
                                  '${_statusLabel(item['status']?.toString() ?? '')}: ${item['count'] ?? 0}',
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortDate(String? value) {
    final date = DateTime.tryParse(value ?? '');
    if (date == null) return value ?? '';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }

  String _statusLabel(String value) => switch (value) {
    'Pending' => 'Na čekanju',
    'Confirmed' => 'Potvrđeni',
    'Completed' => 'Završeni',
    'Cancelled' => 'Otkazani',
    _ => value,
  };
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 240,
    child: Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value, style: Theme.of(context).textTheme.titleLarge),
      ),
    ),
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.max});
  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: LinearProgressIndicator(value: value / max, minHeight: 10),
        ),
        const SizedBox(width: 10),
        Text('$value'),
      ],
    ),
  );
}
