import 'package:flutter/material.dart';

import '../services/admin_api_client.dart';

class ReferenceDataScreen extends StatelessWidget {
  const ReferenceDataScreen({required this.api, super.key});

  final AdminApiClient api;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const Material(
            child: TabBar(
              tabs: [
                Tab(text: 'Gradovi'),
                Tab(text: 'Kategorije usluga'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ReferenceList(api: api, isCategory: false),
                _ReferenceList(api: api, isCategory: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceList extends StatefulWidget {
  const _ReferenceList({required this.api, required this.isCategory});

  final AdminApiClient api;
  final bool isCategory;

  @override
  State<_ReferenceList> createState() => _ReferenceListState();
}

class _ReferenceListState extends State<_ReferenceList> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  String get _endpoint => widget.isCategory ? 'ServiceCategories' : 'Cities';
  String get _title => widget.isCategory ? 'kategoriju' : 'grad';

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
    try {
      final items = await widget.api.getList(_endpoint);
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _ReferenceEditor(item: item, isCategory: widget.isCategory),
    );
    if (result == null) return;
    try {
      final id = item?['id'];
      if (id == null) {
        await widget.api.post(_endpoint, result);
      } else {
        await widget.api.put('$_endpoint/$id', result);
      }
      await _load();
      if (mounted) _showMessage('Izmjene su sačuvane.');
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final name = item['name']?.toString() ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Obrisati ${widget.isCategory ? 'kategoriju' : 'grad'}?'),
        content: Text('„$name“ bit će obrisan/a.'),
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
      await widget.api.delete('$_endpoint/${item['id']}');
      await _load();
      if (mounted) _showMessage('Zapis je obrisan.');
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Osvježi',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.add),
                label: Text('Dodaj $_title'),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
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
        child: Text(
          widget.isCategory
              ? 'Još nema kategorija usluga.'
              : 'Još nema gradova.',
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _items[index];
          return ListTile(
            title: Text(item['name']?.toString() ?? ''),
            subtitle: widget.isCategory
                ? Text(item['description']?.toString() ?? '')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Uredi',
                  onPressed: () => _edit(item),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Obriši',
                  onPressed: () => _delete(item),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReferenceEditor extends StatefulWidget {
  const _ReferenceEditor({required this.isCategory, this.item});

  final bool isCategory;
  final Map<String, dynamic>? item;

  @override
  State<_ReferenceEditor> createState() => _ReferenceEditorState();
}

class _ReferenceEditorState extends State<_ReferenceEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.item?['name']?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.item?['description']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.isCategory ? 'kategoriju usluge' : 'grad';
    return AlertDialog(
      title: Text('${widget.item == null ? 'Dodaj' : 'Uredi'} $label'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: widget.isCategory
                      ? 'Naziv kategorije'
                      : 'Naziv grada',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Naziv je obavezan.'
                    : null,
              ),
              if (widget.isCategory) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Opis'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              if (widget.isCategory)
                'description': _descriptionController.text.trim(),
            });
          },
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }
}
