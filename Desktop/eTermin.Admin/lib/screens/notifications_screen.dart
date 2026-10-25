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

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_refreshing) return;
    _refreshing = true;
    if (mounted) {
      setState(() {
        _loading = _items.isEmpty;
        _error = null;
      });
    }
    try {
      final items = await widget.api.getList('Notifications/my');
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
      _refreshing = false;
    }
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    try {
      await widget.api.put('Notifications/${item['id']}/read', {});
      await _load();
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
      await _load();
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
    if (_items.isEmpty) return const Center(child: Text('Nema obavijesti.'));

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
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
              '${item['message'] ?? ''}\n${_date(item['createdAt'])}',
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
