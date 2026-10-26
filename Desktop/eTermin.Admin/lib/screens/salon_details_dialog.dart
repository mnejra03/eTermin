import 'package:flutter/material.dart';

import '../models/salon.dart';
import '../services/admin_api_client.dart';

class SalonDetailsDialog extends StatefulWidget {
  const SalonDetailsDialog({required this.salon, required this.api, super.key});

  final Salon salon;
  final AdminApiClient api;

  @override
  State<SalonDetailsDialog> createState() => _SalonDetailsDialogState();
}

class _SalonDetailsDialogState extends State<SalonDetailsDialog> {
  late final Future<Map<String, dynamic>> _statistics;

  @override
  void initState() {
    super.initState();
    final query = Uri(
      queryParameters: {
        'salonId': '${widget.salon.id}',
        'status': 'All statuses',
      },
    ).query;
    _statistics = widget.api.getMap('Statistics/dashboard?$query');
  }

  @override
  Widget build(BuildContext context) {
    final salon = widget.salon;
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 760,
        height: 690,
        child: Column(
          children: [
            SizedBox(
              height: 230,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _heroImage(salon.imageUrl, colors),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC17131A)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 22,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                salon.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                salon.cityName,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(salon.isActive),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton.filledTonal(
                      tooltip: 'Zatvori',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _statistics,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _contactCard(salon, colors),
                        if (salon.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _descriptionCard(salon.description, colors),
                        ],
                        const SizedBox(height: 16),
                        Text(
                          'Statistika trenutno nije dostupna.',
                          style: TextStyle(color: colors.error),
                        ),
                      ],
                    );
                  }
                  if (!snapshot.hasData) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _contactCard(salon, colors),
                        if (salon.description.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _descriptionCard(salon.description, colors),
                        ],
                        const SizedBox(height: 16),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    );
                  }

                  final data = snapshot.data!;
                  final services =
                      (data['reservationsByService'] as List? ?? [])
                          .whereType<Map<String, dynamic>>()
                          .toList();
                  final popularUser = data['mostActiveUser']?.toString();
                  final appointmentCount =
                      (data['totalAppointments'] as num?)?.toInt() ?? 0;
                  final userCount = (data['totalUsers'] as num?)?.toInt() ?? 0;

                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _contactCard(salon, colors),
                      if (salon.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _descriptionCard(salon.description, colors),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Pregled salona',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _statCard(
                            Icons.people_outline,
                            'Zaposlenici',
                            '${salon.employeeCount}',
                            colors.primaryContainer,
                          ),
                          _statCard(
                            Icons.event_available_outlined,
                            'Rezervacije',
                            '$appointmentCount',
                            colors.secondaryContainer,
                          ),
                          _statCard(
                            Icons.person_outline,
                            'Korisnici',
                            '$userCount',
                            colors.tertiaryContainer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Najangažovaniji korisnik',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        popularUser == null || popularUser.isEmpty
                            ? 'Još nema rezervacija za ovaj salon.'
                            : '$popularUser · ${data['mostActiveUserCount'] ?? 0} rezervacija',
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Najpopularnije usluge',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      if (services.isEmpty)
                        const Text('Još nema rezervacija za ovaj salon.')
                      else
                        for (final service in services.take(5))
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: colors.primaryContainer,
                              child: Icon(
                                Icons.spa_outlined,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              service['serviceName']?.toString() ?? '',
                            ),
                            trailing: Text('${service['count'] ?? 0} rezervacija'),
                          ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroImage(String imageUrl, ColorScheme colors) {
    if (imageUrl.trim().isEmpty) return _imagePlaceholder(colors);
    return Image.network(
      widget.api.resolveSalonImageUri(imageUrl).toString(),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _imagePlaceholder(colors),
    );
  }

  Widget _imagePlaceholder(ColorScheme colors) => ColoredBox(
    color: colors.primaryContainer,
    child: Center(
      child: Icon(
        Icons.storefront_outlined,
        size: 72,
        color: colors.onPrimaryContainer,
      ),
    ),
  );

  Widget _contactCard(Salon salon, ColorScheme colors) => Card(
    elevation: 0,
    color: colors.surfaceContainerLow,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          _infoRow(Icons.location_on_outlined, 'Adresa', salon.address),
          const Divider(height: 22),
          _infoRow(Icons.phone_outlined, 'Telefon', salon.phoneNumber),
          const Divider(height: 22),
          _infoRow(Icons.email_outlined, 'Email', salon.email),
        ],
      ),
    ),
  );

  Widget _descriptionCard(String description, ColorScheme colors) => Card(
    elevation: 0,
    color: colors.surfaceContainerLowest,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O salonu',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(description),
        ],
      ),
    ),
  );

  Widget _statusBadge(bool isActive) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: isActive ? const Color(0xFFE4F4E8) : const Color(0xFFFFEBD5),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isActive ? Icons.check_circle : Icons.pause_circle,
          size: 17,
          color: isActive ? const Color(0xFF267342) : const Color(0xFF9A5300),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'Aktivan' : 'Neaktivan',
          style: TextStyle(
            color: isActive ? const Color(0xFF205E36) : const Color(0xFF824600),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 12),
      SizedBox(
        width: 74,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
      Expanded(child: Text(value)),
    ],
  );

  Widget _statCard(
    IconData icon,
    String label,
    String value,
    Color background,
  ) =>
      SizedBox(
        width: 205,
        child: Card(
          elevation: 0,
          color: background,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
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
