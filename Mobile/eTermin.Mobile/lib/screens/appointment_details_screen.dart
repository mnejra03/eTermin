import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  const AppointmentDetailsScreen({required this.appointment, super.key});

  final Map<String, dynamic> appointment;

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _isCancelling = false;

  Future<void> _cancelAppointment() async {
    final appointmentId = widget.appointment['id'];
    if (appointmentId is! int) return;

    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkazati termin?'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Razlog otkazivanja'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nazad'),
          ),
          FilledButton(
            onPressed: () {
              final value = reasonController.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Potvrdi otkazivanje'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;

    setState(() => _isCancelling = true);
    try {
      await _apiService.cancelAppointment(appointmentId, reason);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Termin nije otkazan: ${error.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  String _dateTimeText(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return 'Nije dostupno';
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}. u '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final status = appointment['status']?.toString() ?? 'Nepoznato';
    final isPaid = appointment['isPaid'] == true;
    final canCancel = (status == 'Pending' || status == 'Confirmed') && !isPaid;
    final price = (appointment['price'] as num?)?.toDouble() ?? 0;
    final cancellationReason =
        appointment['cancellationReason']?.toString().trim() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalji termina')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _detail(
            Icons.store_outlined,
            'Salon',
            appointment['salonName']?.toString() ?? 'Nije dostupno',
          ),
          _detail(
            Icons.spa_outlined,
            'Usluga',
            appointment['serviceName']?.toString() ?? 'Nije dostupno',
          ),
          _detail(
            Icons.person_outline,
            'Zaposlenik',
            appointment['employeeName']?.toString() ?? 'Nije dostupno',
          ),
          _detail(
            Icons.calendar_month_outlined,
            'Termin',
            _dateTimeText(appointment['startTime']),
          ),
          _detail(
            Icons.payments_outlined,
            'Cijena',
            '${price.toStringAsFixed(2)} KM',
          ),
          _detail(Icons.info_outline, 'Status', _statusLabel(status)),
          _detail(
            isPaid ? Icons.check_circle_outline : Icons.pending_outlined,
            'Plaćanje',
            isPaid ? 'Plaćeno' : 'Nije plaćeno',
          ),
          if (status == 'Cancelled' && cancellationReason.isNotEmpty)
            _detail(
              Icons.notes_outlined,
              'Razlog otkazivanja',
              cancellationReason,
            ),
          if (isPaid && (status == 'Pending' || status == 'Confirmed'))
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Plaćeni termin se ne može otkazati kroz ovaj tok.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          if (canCancel) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isCancelling ? null : _cancelAppointment,
              icon: _isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(_isCancelling ? 'Otkazivanje...' : 'Otkaži termin'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(color: Colors.grey)),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _statusLabel(String status) => switch (status) {
    'Pending' => 'Na čekanju',
    'Confirmed' => 'Potvrđen',
    'Completed' => 'Završen',
    'Cancelled' => 'Otkazan',
    _ => status,
  };
}
