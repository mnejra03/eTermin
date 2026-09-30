import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../models/service.dart';
import '../models/employee.dart';
import '../services/api_service.dart';


import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final Salon salon;
  final Service service;

  final DateTime? initialDate;

  final int? initialEmployeeId;

  const BookingScreen({
    super.key,
    required this.salon,
    required this.service,
    this.initialDate,
    this.initialEmployeeId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with WidgetsBindingObserver {
  String? _paypalOrderId;
  int? _paymentId;

  late DateTime selectedDate;
  String? selectedTime;

  final ApiService _apiService = ApiService();

  List<Employee> employees = [];
  Employee? selectedEmployee;

  bool isLoadingEmployees = true;
  String? employeesError;

  final Color primaryColor = const Color(0xFF7568F5);

  List<Map<String, dynamic>> availableSlots = [];
  bool isLoadingSlots = false;
  String? slotsError;
  bool isBooking = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    selectedDate = widget.initialDate ?? DateTime.now();

    _loadEmployees();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _capturePayPalPayment();
    }
  }

  Future<void> _loadEmployees() async {
    try {
      final allEmployees = await _apiService.getEmployees();

      final filteredEmployees = allEmployees.where((employee) {
        return employee.isActive &&
            employee.salonId == widget.salon.id &&
            employee.serviceIds.contains(widget.service.id);
      }).toList();

      if (!mounted) return;

      setState(() {
        employees = filteredEmployees;
        isLoadingEmployees = false;

        if (filteredEmployees.isNotEmpty) {
          if (widget.initialEmployeeId != null) {
            final matchingEmployee = filteredEmployees.where(
              (employee) => employee.id == widget.initialEmployeeId,
            );

            if (matchingEmployee.isNotEmpty) {
              selectedEmployee = matchingEmployee.first;
            } else {
              selectedEmployee = filteredEmployees.first;
            }
          } else {
            selectedEmployee = filteredEmployees.first;
          }
        }
      });
      if (selectedEmployee != null) {
        await _loadAvailableSlots();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingEmployees = false;
        employeesError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (selectedEmployee == null) {
      return;
    }

    setState(() {
      isLoadingSlots = true;
      slotsError = null;
      availableSlots = [];
      selectedTime = null;
    });

    try {
      final slots = await _apiService.getAvailableSlots(
        salonId: widget.salon.id,
        employeeId: selectedEmployee!.id,
        serviceId: widget.service.id,
        date: selectedDate,
      );

      if (!mounted) return;

      setState(() {
        availableSlots = slots;
        isLoadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingSlots = false;
        slotsError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (selectedEmployee == null || selectedTime == null) {
      return;
    }

    final selectedSlot = availableSlots.firstWhere((slot) {
      final startTime = DateTime.parse(slot['startTime'].toString());

      final time =
          '${startTime.hour.toString().padLeft(2, '0')}:'
          '${startTime.minute.toString().padLeft(2, '0')}';

      return time == selectedTime;
    });

    final isAvailable = selectedSlot['isAvailable'] == true;

    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ovaj termin je zauzet. Odaberite drugi termin.'),
        ),
      );
      return;
    }

    final startTime = DateTime.parse(selectedSlot['startTime'].toString());

    final endTime = DateTime.parse(selectedSlot['endTime'].toString());

    setState(() {
      isBooking = true;
    });

    try {
      // 1. Kreiranje termina
      final appointmentId = await _apiService.createAppointment(
        salonId: widget.salon.id,
        employeeId: selectedEmployee!.id,
        serviceId: widget.service.id,
        startTime: startTime,
        endTime: endTime,
        price: widget.service.price,
      );

      // 2. Kreiranje Pending Payment zapisa
      final paymentId = await _apiService.createPayment(
        appointmentId: appointmentId,
        amount: widget.service.price,
        paymentMethod: 'PayPal',
      );

      // 3. Kreiranje PayPal Ordera
      final paypalOrder = await _apiService.createPayPalOrder(
        amount: widget.service.price,
        currency: 'BAM',
        description: '${widget.service.name} - ${widget.salon.name}',
      );

      final approvalUrl = paypalOrder['approvalUrl']?.toString();

      final orderId = paypalOrder['orderId']?.toString();

      _paypalOrderId = orderId;
      _paymentId = paymentId;

      if (approvalUrl == null ||
          approvalUrl.isEmpty ||
          orderId == null ||
          orderId.isEmpty) {
        throw Exception('PayPal nije vratio potrebne podatke.');
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            salon: widget.salon,
            service: widget.service,
            selectedDate: selectedDate,
            selectedTime: selectedTime!,
            appointmentId: appointmentId,
            paymentId: paymentId,
            orderId: orderId,
            approvalUrl: approvalUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          isBooking = false;
        });
      }
    }
  }

  Future<void> _capturePayPalPayment() async {
    if (_paypalOrderId == null || _paymentId == null) {
      return;
    }

    try {
      await _apiService.capturePayPalOrder(
        orderId: _paypalOrderId!,
        paymentId: _paymentId!,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PayPal plaćanje je uspješno završeno.')),
      );

      setState(() {
        _paypalOrderId = null;
        _paymentId = null;
        selectedTime = null;
      });

      await _loadAvailableSlots();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ==========================
      // APP BAR
      // ==========================
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF7568F5),
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'eTermin',
          style: TextStyle(
            color: Color(0xFF7568F5),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================
                  // NAZIV USLUGE + SALONA
                  // ==========================
                  Row(
                    children: [
                      const Text('✂️', style: TextStyle(fontSize: 25)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.service.name} - ${widget.salon.name}',
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Odaberi zaposlenika:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  if (isLoadingEmployees)
                    const Center(child: CircularProgressIndicator())
                  else if (employeesError != null)
                    Text(
                      employeesError!,
                      style: const TextStyle(color: Colors.red),
                    )
                  else if (employees.isEmpty)
                    const Text(
                      'Nema dostupnih zaposlenika za ovu uslugu.',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    DropdownButtonFormField<Employee>(
                      initialValue: selectedEmployee,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: employees.map((employee) {
                        return DropdownMenuItem<Employee>(
                          value: employee,
                          child: Text(employee.fullName),
                        );
                      }).toList(),
                      onChanged: (employee) async {
                        setState(() {
                          selectedEmployee = employee;
                          selectedTime = null;
                        });

                        await _loadAvailableSlots();
                      },
                    ),

                  const SizedBox(height: 18),

                  const Text(
                    'Odaberi datum:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  // ==========================
                  // KALENDAR
                  // ==========================
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CalendarDatePicker(
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                      onDateChanged: (date) async {
                        setState(() {
                          selectedDate = date;
                          selectedTime = null;
                        });

                        await _loadAvailableSlots();
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ==========================
                  // SLOBODNI TERMINI
                  // ==========================
                  Row(
                    children: [
                      const Text(
                        'Slobodni termini za ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          '${selectedDate.day.toString().padLeft(2, '0')}. '
                          '${selectedDate.month.toString().padLeft(2, '0')}. '
                          '${selectedDate.year}.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ==========================
                  // TERMINI
                  // ==========================
                  if (isLoadingSlots)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (slotsError != null)
                    Text(slotsError!, style: const TextStyle(color: Colors.red))
                  else if (availableSlots.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Nema slobodnih termina za odabrani datum.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: availableSlots.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.8,
                          ),
                      itemBuilder: (context, index) {
                        final slot = availableSlots[index];

                        final startTime = DateTime.parse(
                          slot['startTime'].toString(),
                        );

                        final time =
                            '${startTime.hour.toString().padLeft(2, '0')}:'
                            '${startTime.minute.toString().padLeft(2, '0')}';

                        final isAvailable = slot['isAvailable'] == true;
                        final isSelected = selectedTime == time;

                        return OutlinedButton(
                          onPressed: isAvailable
                              ? () {
                                  setState(() {
                                    selectedTime = time;
                                  });
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !isAvailable
                                ? Colors.grey.shade200
                                : isSelected
                                ? primaryColor.withValues(alpha: 0.12)
                                : Colors.white,
                            foregroundColor: !isAvailable
                                ? Colors.grey
                                : primaryColor,
                            side: BorderSide(
                              color: !isAvailable
                                  ? Colors.grey.shade400
                                  : primaryColor,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                  color: !isAvailable
                                      ? Colors.grey
                                      : primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                isAvailable ? 'Slobodno' : 'Zauzeto',
                                style: TextStyle(
                                  color: !isAvailable
                                      ? Colors.grey
                                      : Colors.green,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // ==========================
                  // POTVRDI TERMIN
                  // ==========================
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: selectedTime == null || isBooking
                          ? null
                          : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        disabledBackgroundColor: primaryColor.withValues(
                          alpha: 0.5,
                        ),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        isBooking ? 'Rezervacija...' : 'Potvrdi termin',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==========================
          // BOTTOM NAVIGATION
          // ==========================
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E0EA))),
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: primaryColor,
        selectedFontSize: 9,
        unselectedFontSize: 9,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Početna',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Pretraži'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Termini',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
