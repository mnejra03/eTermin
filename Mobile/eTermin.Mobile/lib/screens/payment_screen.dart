import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/salon.dart';
import '../models/service.dart';
import '../services/api_service.dart';

import 'package:app_links/app_links.dart';

import 'dart:async';

class PaymentScreen extends StatefulWidget {
  final Salon salon;
  final Service service;
  final DateTime selectedDate;
  final String selectedTime;

  final int appointmentId;
  final int paymentId;
  final String orderId;
  final String approvalUrl;

  const PaymentScreen({
    super.key,
    required this.salon,
    required this.service,
    required this.selectedDate,
    required this.selectedTime,
    required this.appointmentId,
    required this.paymentId,
    required this.orderId,
    required this.approvalUrl,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  bool _isPaying = false;
  bool _paymentStarted = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == 'etermin' && uri.host == 'paypal-return') {
        _capturePayment();
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _paymentStarted) {
      _capturePayment();
    }
  }

  Future<void> _startPayPalPayment() async {
    setState(() {
      _isPaying = true;
      _paymentStarted = true;
    });

    try {
      final uri = Uri.parse(widget.approvalUrl);

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened) {
        throw Exception('PayPal checkout se ne može otvoriti.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPaying = false;
        _paymentStarted = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _capturePayment() async {
    if (!_paymentStarted || _isPaying == false) {
      return;
    }
    

    try {
      await _apiService.capturePayPalOrder(
        orderId: widget.orderId,
        paymentId: widget.paymentId,
      );

      if (!mounted) return;

      setState(() {
        _isPaying = false;
        _paymentStarted = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plaćanje je uspješno završeno.')),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isPaying = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Plaćanje još nije završeno. '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${widget.selectedDate.day.toString().padLeft(2, '0')}.'
        '${widget.selectedDate.month.toString().padLeft(2, '0')}.'
        '${widget.selectedDate.year}.';

    return Scaffold(
      appBar: AppBar(title: const Text('Plaćanje')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),

            const Center(child: Icon(Icons.payment, size: 70)),

            const SizedBox(height: 25),

            _infoRow(Icons.store, 'Salon', widget.salon.name),

            _infoRow(Icons.spa, 'Usluga', widget.service.name),

            _infoRow(Icons.calendar_today, 'Datum', formattedDate),

            _infoRow(Icons.access_time, 'Vrijeme', widget.selectedTime),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ukupno za plaćanje',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${widget.service.price.toStringAsFixed(2)} KM',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Odaberite način plaćanja',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.payment, size: 35),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Text(
                      'PayPal',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.check_circle, size: 25),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isPaying ? null : _startPayPalPayment,
                child: _isPaying
                    ? const CircularProgressIndicator()
                    : Text(
                        'Plati ${widget.service.price.toStringAsFixed(2)} KM',
                      ),
              ),
            ),

            const SizedBox(height: 12),

            const Center(
              child: Text(
                'Sigurno plaćanje putem PayPal-a',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 25),
          const SizedBox(width: 12),
          Text('$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
