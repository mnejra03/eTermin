import 'dart:async';

import 'package:flutter/material.dart';

import '../services/admin_api_client.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({required this.api, super.key});

  final AdminApiClient api;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  static const _pageSize = 8;
  List<Map<String, dynamic>> _users = [];
  int _totalCount = 0;
  int _totalPages = 1;
  bool _loading = true;
  String? _error;
  String _search = '';
  int _page = 1;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.getPagedList(
        'Users',
        page: page,
        pageSize: _pageSize,
        queryParameters: _search.trim().isEmpty
            ? const {}
            : {'search': _search.trim()},
      );
      if (mounted) {
        setState(() {
          _users = result.items;
          _totalCount = result.totalCount;
          _totalPages = result.totalPages;
          _page = result.page;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _date(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (parsed == null) return '—';
    return '${parsed.day.toString().padLeft(2, '0')}.${parsed.month.toString().padLeft(2, '0')}.${parsed.year}';
  }

  @override
  Widget build(BuildContext context) {
    final page = _page.clamp(1, _totalPages).toInt();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Pretraži ime, email ili ulogu',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => _search = value);
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 350),
                      () => _load(),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Chip(
                avatar: const Icon(Icons.people_outline, size: 18),
                label: Text('$_totalCount korisnika'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Osvježi korisnike',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(_users)),
        if (!_loading && _error == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Prethodna stranica',
                  onPressed: _loading || page <= 1
                      ? null
                      : () => _load(page: page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Stranica $page od $_totalPages'),
                ),
                IconButton(
                  tooltip: 'Sljedeća stranica',
                  onPressed: _loading || page >= _totalPages
                      ? null
                      : () => _load(page: page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> visible) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Korisnike nije moguće učitati: $_error'),
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
          _totalCount == 0
              ? 'Nema korisnika u bazi.'
              : 'Nema korisnika koji odgovaraju pretrazi.',
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 840,
            maxHeight: constraints.maxHeight,
          ),
          child: Card(
            margin: const EdgeInsets.fromLTRB(24, 4, 24, 16),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              shrinkWrap: true,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 32,
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Korisnik')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Uloga')),
                      DataColumn(label: Text('Registrovan')),
                    ],
                    rows: [
                      for (final user in visible)
                        DataRow(
                          cells: [
                            DataCell(Text('${user['id'] ?? '—'}')),
                            DataCell(
                              Text(
                                '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'
                                    .trim(),
                              ),
                            ),
                            DataCell(Text(user['email']?.toString() ?? '')),
                            DataCell(
                              _RoleBadge(role: user['role']?.toString() ?? ''),
                            ),
                            DataCell(Text(_date(user['createdAt']))),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role.toLowerCase() == 'admin';
    final color = isAdmin ? const Color(0xFF6750A4) : const Color(0xFF3974B8);
    return Chip(
      avatar: Icon(
        isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
        size: 16,
        color: color,
      ),
      label: Text(isAdmin ? 'Administrator' : 'Korisnik'),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(color: color.withValues(alpha: 0.25)),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}
