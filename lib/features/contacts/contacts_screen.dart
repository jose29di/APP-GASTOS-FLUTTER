import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/database/app_database.dart';
import 'package:gastos_erp_tracker/core/services/auth_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filtered = [];
  String _filter = 'Todos';
  final _searchCon = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService.currentUser();
    if (user == null) return;
    final contacts = await AppDatabase.query(
      'contacts',
      where: 'owner_id = ?',
      whereArgs: [user['id']],
      orderBy: 'name ASC',
    );
    if (mounted) {
      setState(() {
        _contacts = contacts;
        _filtered = contacts;
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    final query = _searchCon.text.toLowerCase();
    setState(() {
      _filtered = _contacts.where((c) {
        final matchesSearch = c['name'].toString().toLowerCase().contains(query) ||
            c['identification']?.toString().toLowerCase().contains(query) == true;
        final matchesFilter = _filter == 'Todos' || c['category'] == _filter.toLowerCase();
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar contacto'),
        content: const Text('¿Estás seguro? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      await AppDatabase.delete('contacts', where: 'id = ?', whereArgs: [id]);
      _load();
    }
  }

  Color _categoryColor(String cat) {
    switch (cat.toLowerCase()) {
      case 'cliente': return Colors.blue;
      case 'proveedor': return Colors.orange;
      case 'obrero': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat.toLowerCase()) {
      case 'cliente': return Icons.person_outline;
      case 'proveedor': return Icons.storefront_outlined;
      case 'obrero': return Icons.engineering_outlined;
      default: return Icons.contact_page_outlined;
    }
  }

  @override
  void dispose() {
    _searchCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Contactos')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchCon,
                    onChanged: (_) => _applyFilter(),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o identificación',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCon.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () { _searchCon.clear(); _applyFilter(); },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: ['Todos', 'Clientes', 'Proveedores', 'Obreros']
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f),
                                selected: _filter == f,
                                onSelected: (_) { setState(() => _filter = f); _applyFilter(); },
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: scheme.onSurfaceVariant.withValues(alpha: .4)),
                              const SizedBox(height: 12),
                              Text('No hay contactos aún', style: Theme.of(context).textTheme.bodyLarge),
                              const SizedBox(height: 4),
                              Text('Agrega clientes, proveedores u obreros', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (context, index) {
                              final c = _filtered[index];
                              final cat = c['category'] as String;
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _categoryColor(cat).withValues(alpha: .15),
                                    child: Icon(_categoryIcon(cat), color: _categoryColor(cat)),
                                  ),
                                  title: Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _categoryColor(cat).withValues(alpha: .12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          cat[0].toUpperCase() + cat.substring(1),
                                          style: TextStyle(fontSize: 11, color: _categoryColor(cat), fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      if (c['identification'] != null && (c['identification'] as String).isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(c['identification'] as String, style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ],
                                  ),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (_) => [
                                      PopupMenuItem(
                                        child: const ListTile(
                                          leading: Icon(Icons.edit_outlined),
                                          title: Text('Editar'),
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onTap: () async {
                                          await Navigator.push(context, MaterialPageRoute(
                                            builder: (_) => ContactFormScreen(contact: c),
                                          ));
                                          _load();
                                        },
                                      ),
                                      PopupMenuItem(
                                        child: const ListTile(
                                          leading: Icon(Icons.delete_outlined, color: Colors.red),
                                          title: Text('Eliminar', style: TextStyle(color: Colors.red)),
                                          dense: true,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onTap: () => _delete(c['id'] as int),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => const ContactFormScreen(),
          ));
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ContactFormScreen extends StatefulWidget {
  final Map<String, dynamic>? contact;
  const ContactFormScreen({super.key, this.contact});

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _nameCon = TextEditingController();
  final _idCon = TextEditingController();
  final _phoneCon = TextEditingController();
  final _emailCon = TextEditingController();
  final _notesCon = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _category = 'cliente';
  bool _recurring = false;

  @override
  void initState() {
    super.initState();
    if (widget.contact != null) {
      _nameCon.text = widget.contact!['name'] as String;
      _idCon.text = widget.contact!['identification'] as String? ?? '';
      _phoneCon.text = widget.contact!['phone'] as String? ?? '';
      _emailCon.text = widget.contact!['email'] as String? ?? '';
      _notesCon.text = widget.contact!['notes'] as String? ?? '';
      _category = widget.contact!['category'] as String? ?? 'cliente';
      _recurring = (widget.contact!['is_recurring'] as int?) == 1;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = await AuthService.currentUser();
    if (user == null) return;

    final data = {
      'owner_id': user['id'],
      'name': _nameCon.text.trim(),
      'identification': _idCon.text.trim(),
      'category': _category,
      'phone': _phoneCon.text.trim(),
      'email': _emailCon.text.trim(),
      'is_recurring': _recurring ? 1 : 0,
      'notes': _notesCon.text.trim(),
    };

    if (widget.contact != null) {
      await AppDatabase.update('contacts', data, where: 'id = ?', whereArgs: [widget.contact!['id']]);
    } else {
      await AppDatabase.insert('contacts', data);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameCon.dispose();
    _idCon.dispose();
    _phoneCon.dispose();
    _emailCon.dispose();
    _notesCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.contact != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar contacto' : 'Nuevo contacto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCon,
              decoration: const InputDecoration(labelText: 'Nombre / Razón social', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _idCon,
              decoration: const InputDecoration(labelText: 'RUC / Cédula / ID', prefixIcon: Icon(Icons.badge_outlined)),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Categoría', prefixIcon: Icon(Icons.category_outlined)),
              items: const [
                DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                DropdownMenuItem(value: 'proveedor', child: Text('Proveedor')),
                DropdownMenuItem(value: 'obrero', child: Text('Obrero / Jornal')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'cliente'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCon,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCon,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email_outlined)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesCon,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notas', prefixIcon: Icon(Icons.notes_outlined)),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              title: const Text('Es proveedor recurrente'),
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar contacto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
