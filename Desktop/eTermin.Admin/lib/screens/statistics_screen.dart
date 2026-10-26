import 'dart:math' as math;
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
                  child: _StatusPieChart(
                    items: byStatus,
                    labelFor: _statusLabel,
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

class _StatusSlice {
  const _StatusSlice(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

class _StatusPieChart extends StatelessWidget {
  const _StatusPieChart({required this.items, required this.labelFor});

  final List<Map<String, dynamic>> items;
  final String Function(String) labelFor;

  Color _colorFor(String status) => switch (status) {
    'Pending' => const Color(0xFFE99A24),
    'Confirmed' => const Color(0xFF3978C5),
    'Completed' => const Color(0xFF32936F),
    'Cancelled' => const Color(0xFFD65B5B),
    _ => const Color(0xFF718096),
  };

  @override
  Widget build(BuildContext context) {
    final slices = items.map((item) {
      final status = item['status']?.toString() ?? '';
      return _StatusSlice(
        labelFor(status),
        (item['count'] as num? ?? 0).toInt(),
        _colorFor(status),
      );
    }).where((slice) => slice.count > 0).toList();
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.count);

    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Nema podataka za odabrani period.'),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 170,
          height: 170,
          child: CustomPaint(
            painter: _StatusPiePainter(slices),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final slice in slices)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: slice.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(slice.label, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${slice.count} (${(slice.count * 100 / total).round()}%)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 16),
              Text(
                'Ukupno: $total',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusPiePainter extends CustomPainter {
  const _StatusPiePainter(this.slices);

  final List<_StatusSlice> slices;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.count);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.46;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    var startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice.count / total) * math.pi * 2;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(startAngle) * radius,
          center.dy + math.sin(startAngle) * radius,
        )
        ..arcTo(bounds, startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path, Paint()..color = slice.color);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _StatusPiePainter oldDelegate) =>
      oldDelegate.slices != slices;
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
    width: 240,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: scheme.primaryContainer,
          child: Icon(icon, color: scheme.primary),
        ),
        title: Text(title, style: Theme.of(context).textTheme.labelLarge),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
      ),
    ),
    );
  }
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
          Row(children: [
            Icon(Icons.insights_outlined, color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ]),
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (value / max).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}
