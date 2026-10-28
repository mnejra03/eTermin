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
  static const _purple = Color(0xFF7568F5);

  Future<void> _cancelAppointment() async {
    final appointmentId = widget.appointment['id'];
    if (appointmentId is! int) return;

    final reasonController = TextEditingController();
    String? reasonError;
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Otkazati termin?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unesite razlog kako bi vlasnik termina znao zašto je otkazan.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLength: 500,
                onChanged: (value) {
                  if (value.trim().isNotEmpty && reasonError != null) {
                    setDialogState(() => reasonError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Razlog otkazivanja',
                  hintText: 'Npr. promjena planova',
                  errorText: reasonError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Nazad'),
            ),
            FilledButton(
              onPressed: () {
                final value = reasonController.text.trim();
                if (value.isEmpty) {
                  setDialogState(
                    () => reasonError =
                        'Razlog je obavezan za otkazivanje termina.',
                  );
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Potvrdi otkazivanje'),
            ),
          ],
        ),
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
    final status = appointment['status']?.toString() ?? 'Unknown';
    final isPaid = appointment['isPaid'] == true;
    final canCancel = (status == 'Pending' || status == 'Confirmed') && !isPaid;
    final price = (appointment['price'] as num?)?.toDouble() ?? 0;
    final salonName = appointment['salonName']?.toString() ?? 'Salon';
    final serviceName = appointment['serviceName']?.toString() ?? 'Usluga';
    final cancellationReason =
        appointment['cancellationReason']?.toString().trim() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FB),
      appBar: AppBar(
        title: const Text('Detalji termina'),
        backgroundColor: const Color(0xFFF7F6FB),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7568F5), Color(0xFF9D70E8)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _purple.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'PREGLED TERMINA',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  serviceName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        salonName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Informacije o terminu'),
          _detail(
            Icons.calendar_month_outlined,
            'Datum i vrijeme',
            _dateTimeText(appointment['startTime']),
          ),
          _detail(
            Icons.person_outline_rounded,
            'Zaposlenik',
            appointment['employeeName']?.toString() ?? 'Nije dostupno',
          ),
          _detail(Icons.store_outlined, 'Salon', salonName),
          _detail(Icons.spa_outlined, 'Usluga', serviceName),
          const SizedBox(height: 16),
          _sectionTitle('Pla\u0107anje'),
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEAE7F2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isPaid
                        ? const Color(0xFFE9F8F0)
                        : const Color(0xFFFFF5E2),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    isPaid ? Icons.check_rounded : Icons.schedule_rounded,
                    color: isPaid
                        ? const Color(0xFF168451)
                        : const Color(0xFFB7791F),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ukupna cijena',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isPaid ? 'Pla\u0107eno' : 'Nije pla\u0107eno',
                        style: TextStyle(
                          color: isPaid
                              ? const Color(0xFF168451)
                              : const Color(0xFFB7791F),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${price.toStringAsFixed(2)} KM',
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (status == 'Cancelled' && cancellationReason.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF4D2CF)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFB5473C),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Razlog otkazivanja',
                          style: TextStyle(
                            color: Color(0xFF8E352D),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          cancellationReason,
                          style: const TextStyle(
                            color: Color(0xFF5F3835),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isPaid && (status == 'Pending' || status == 'Confirmed')) ...[
            const SizedBox(height: 12),
            _notice(
              'Pla\u0107eni termin se ne mo\u017ee otkazati kroz ovaj tok.',
              Icons.lock_outline_rounded,
            ),
          ],
          if (canCancel) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isCancelling ? null : _cancelAppointment,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB5473C),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: _isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(
                _isCancelling ? 'Otkazivanje...' : 'Otka\u017ei termin',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(top: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEAE7F2)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F1FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _purple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      title,
      style: const TextStyle(
        color: Color(0xFF292638),
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _statusBadge(String status) {
    final color = switch (status) {
      'Pending' => const Color(0xFFFFC857),
      'Confirmed' => const Color(0xFF7FE0B1),
      'Completed' => const Color(0xFFB9D9FF),
      'Cancelled' => const Color(0xFFFFA9A1),
      _ => Colors.white70,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: const TextStyle(
          color: Color(0xFF332B50),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _notice(String message, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF1EFF8),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: [
        Icon(icon, color: _purple, size: 18),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(fontSize: 12, height: 1.35),
          ),
        ),
      ],
    ),
  );

  String _statusLabel(String status) => switch (status) {
    'Pending' => 'Na \u010dekanju',
    'Confirmed' => 'Potvr\u0111en',
    'Completed' => 'Zavr\u0161en',
    'Cancelled' => 'Otkazan',
    _ => status,
  };
}
