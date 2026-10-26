import 'dart:async';

import 'package:flutter/material.dart';

import '../services/admin_api_client.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({required this.api, super.key});

  final AdminApiClient api;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  Timer? _refreshTimer;
  bool _refreshing = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _load(page: _page),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (mounted) {
      setState(() {
        _loading = _items.isEmpty;
        _error = null;
      });
    }
    try {
      final response = await widget.api.tryGetMap(
        'Notifications/admin?page=$page',
      );
      if (!response.succeeded) {
        if (mounted) {
          setState(() => _error = _friendlyLoadError(
            response.message ?? 'Obavijesti se ne mogu učitati.',
          ));
        }
        return;
      }
      final body = response.data;
      if (body == null || body['items'] is! List) {
        if (mounted) {
          setState(() => _error = 'API je vratio neispravan spisak obavijesti.');
        }
        return;
      }
      if (mounted) {
        setState(() {
          _items = (body['items'] as List)
              .whereType<Map<String, dynamic>>()
              .toList();
          _page = (body['page'] as num?)?.toInt() ?? page;
          _totalPages = (body['totalPages'] as num?)?.toInt() ?? 1;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyLoadError(error.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
      _refreshing = false;
    }
  }

  String _friendlyLoadError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains("'admin'") ||
        lower.contains('not a valid') ||
        lower.contains('http 400')) {
      return 'API servis još nema novu rutu za obavijesti administratora. Ponovo izgradite i pokrenite API servis, pa osvježite ovaj tab.';
    }
    return message.replaceFirst('ApiException: ', '');
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    try {
      await widget.api.put('Notifications/${item['id']}/read', {});
      await _load(page: _page);
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obrisati obavijest?'),
        content: Text(
          'Obavijest „${item['title'] ?? ''}“ će biti trajno obrisana.',
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
      await widget.api.delete('Notifications/${item['id']}');
      await _load(page: _page);
    } catch (error) {
      if (mounted) _message(error.toString());
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year} ${two(date.hour)}:${two(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
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
    if (_items.isEmpty) {
      return Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_none, size: 44,
                color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text('Trenutno nema obavijesti.',
                style: Theme.of(context).textTheme.titleMedium),
            ]),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == _items.length) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Prethodna stranica',
                onPressed: _refreshing || _page <= 1
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
                onPressed: _refreshing || _page >= _totalPages
                    ? null
                    : () => _load(page: _page + 1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          );
        }
        final item = _items[index];
        final read = item['isRead'] == true;
        return Card(
          child: ListTile(
            leading: Icon(
              read
                  ? Icons.notifications_none
                  : Icons.notifications_active_outlined,
            ),
            title: Text(
              item['title']?.toString() ?? '',
              style: TextStyle(
                fontWeight: read ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${item['message'] ?? ''}\nZa: ${item['userName'] ?? 'Korisnik'} · ${_date(item['createdAt'])}',
            ),
            isThreeLine: true,
            trailing: Wrap(
              spacing: 4,
              children: [
                if (!read)
                  IconButton(
                    tooltip: 'Označi kao pročitano',
                    onPressed: () => _markRead(item),
                    icon: const Icon(Icons.mark_email_read_outlined),
                  ),
                IconButton(
                  tooltip: 'Obriši',
                  onPressed: () => _delete(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
