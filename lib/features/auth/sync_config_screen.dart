import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/services/auth_service.dart';
import 'package:gastos_erp_tracker/core/services/sync_service.dart';

class SyncConfigScreen extends StatefulWidget {
  const SyncConfigScreen({super.key});

  @override
  State<SyncConfigScreen> createState() => _SyncConfigScreenState();
}

class _SyncConfigScreenState extends State<SyncConfigScreen> {
  final _urlCon = TextEditingController();
  final _apiKeyCon = TextEditingController();
  final _anonKeyCon = TextEditingController();
  final _tursoUrlCon = TextEditingController();
  final _tursoTokenCon = TextEditingController();
  bool _autoSync = false;
  int _interval = 15;
  String _provider = 'supabase';
  bool _loading = true;
  bool _testing = false;
  bool _syncing = false;
  bool _showTursoToken = false;
  double _syncProgress = 0.0;
  String _syncStatus = '';
  String? _lastSync;
  String? _lastStatus;

  @override
  void initState() {
    super.initState();
    SyncService.onProgress = _onSyncProgress;
    _load();
  }

  @override
  void dispose() {
    SyncService.onProgress = null;
    _urlCon.dispose();
    _apiKeyCon.dispose();
    _anonKeyCon.dispose();
    _tursoUrlCon.dispose();
    _tursoTokenCon.dispose();
    super.dispose();
  }

  void _onSyncProgress(SyncProgress p) {
    if (mounted) setState(() {
      _syncProgress = p.progress;
      _syncStatus = p.status;
    });
  }

  Future<void> _load() async {
    final config = await SyncService.getConfig();
    if (config != null && mounted) {
      _urlCon.text = config.serverUrl ?? '';
      _apiKeyCon.text = config.apiKey ?? '';
      _anonKeyCon.text = config.anonKey ?? '';
      _tursoUrlCon.text = config.tursoUrl ?? '';
      _tursoTokenCon.text = config.tursoToken ?? '';
      _autoSync = config.autoSync;
      _interval = config.syncIntervalMinutes;
      _provider = config.provider;
      _lastSync = config.lastSyncAt;
      _lastStatus = config.lastSyncStatus;
    }
    setState(() => _loading = false);
  }

  void _save() async {
    await SyncService.saveConfig(SyncConfig(
      provider: _provider,
      serverUrl: _urlCon.text.trim(),
      apiKey: _apiKeyCon.text.trim(),
      anonKey: _anonKeyCon.text.trim(),
      tursoUrl: _tursoUrlCon.text.trim(),
      tursoToken: _tursoTokenCon.text.trim(),
      autoSync: _autoSync,
      syncIntervalMinutes: _interval,
      isEnabled: _provider == 'turso'
          ? _tursoUrlCon.text.trim().isNotEmpty && _tursoTokenCon.text.trim().isNotEmpty
          : _urlCon.text.trim().isNotEmpty && _apiKeyCon.text.trim().isNotEmpty,
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() => _testing = true);
    final result = await SyncService.testConnection(SyncConfig(
      provider: _provider,
      serverUrl: _urlCon.text.trim(),
      apiKey: _apiKeyCon.text.trim(),
      tursoUrl: _tursoUrlCon.text.trim(),
      tursoToken: _tursoTokenCon.text.trim(),
    ));
    if (mounted) {
      final ok = result == 'ok';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Conexión exitosa' : result),
          backgroundColor: ok ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _testing = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() {
      _syncing = true;
      _syncProgress = 0.0;
      _syncStatus = 'Iniciando...';
    });
    final result = await SyncService.syncAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['success'] == true
              ? 'Sincronizado correctamente'
              : 'Error: ${result['error']}'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _syncing = false);
      _load();
    }
  }

  Future<void> _restore() async {
    // Paso 1: Confirmación inicial
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar desde la nube'),
        content: const Text(
          'Esta acción REEMPLAZARÁ todos tus datos locales con los del servidor.\n\n'
          '¿Estás seguro de continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    // Paso 2: Validación humana (multiplicación aleatoria)
    final rng = Random();
    final a = rng.nextInt(9) + 1;
    final b = rng.nextInt(9) + 1;
    final correctAnswer = a * b;
    final answerCon = TextEditingController();
    final humanValid = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verificación humana'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Resuelve la siguiente operación para confirmar:'),
            const SizedBox(height: 16),
            Text('$a × $b = ?', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: answerCon,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Respuesta'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final ans = int.tryParse(answerCon.text.trim());
              if (ans == correctAnswer) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Respuesta incorrecta'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );
    answerCon.dispose();
    if (humanValid != true || !mounted) return;

    // Paso 3: Contraseña del usuario
    final passCon = TextEditingController();
    final passValid = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar con contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Ingresa tu contraseña para autorizar la restauración:'),
            const SizedBox(height: 12),
            TextField(
              controller: passCon,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final ok = await AuthService.validatePassword(passCon.text.trim());
              if (ok) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Contraseña incorrecta'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Autorizar'),
          ),
        ],
      ),
    );
    passCon.dispose();
    if (passValid != true || !mounted) return;

    // Paso 4: Ejecutar restauración
    setState(() {
      _syncing = true;
      _syncProgress = 0.0;
      _syncStatus = 'Restaurando...';
    });
    await Future.delayed(const Duration(milliseconds: 50));
    final result = await SyncService.restoreFromRemote();
    if (mounted) {
      setState(() => _syncing = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restauración completada'), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error en restauración'),
            content: Text(result['error']?.toString() ?? 'Error desconocido'),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
          ),
        );
      }
      _load();
    }
  }

  String _providerLabel(String p) {
    switch (p) {
      case 'turso': return 'Turso (libSQL)';
      case 'supabase': return 'Supabase';
      case 'custom': return 'Servidor propio (REST API)';
      default: return p;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final scheme = Theme.of(context).colorScheme;
    final isTurso = _provider == 'turso';
    final configured = isTurso
        ? _tursoUrlCon.text.isNotEmpty && _tursoTokenCon.text.isNotEmpty
        : _urlCon.text.isNotEmpty && _apiKeyCon.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Sincronización en la nube')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(configured ? Icons.cloud_done_outlined : Icons.cloud_outlined,
                          color: configured ? Colors.green : Colors.grey),
                      const SizedBox(width: 10),
                      Text('Estado de la nube', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Proveedor: ${_providerLabel(_provider)}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  if (_lastSync != null) ...[
                    Text('Última sincronización: ${_lastSync!.length >= 19 ? '${_lastSync!.substring(0, 19).replaceAll('T', ' ')}' : _lastSync}',
                        style: Theme.of(context).textTheme.bodySmall),
                    if (_lastStatus != null)
                      Text('Estado: $_lastStatus', style: Theme.of(context).textTheme.bodySmall),
                  ] else
                    Text('No se ha sincronizado aún', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Barra de progreso
          if (_syncing) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, value: _syncProgress > 0 ? _syncProgress : null),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(_syncStatus, style: Theme.of(context).textTheme.bodyMedium)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _syncProgress,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text('${(_syncProgress * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          DropdownButtonFormField<String>(
            initialValue: _provider,
            decoration: const InputDecoration(labelText: 'Proveedor'),
            items: const [
              DropdownMenuItem(value: 'supabase', child: Text('Supabase')),
              DropdownMenuItem(value: 'custom', child: Text('Servidor propio (REST API)')),
              DropdownMenuItem(value: 'turso', child: Text('Turso (libSQL)')),
            ],
            onChanged: (v) => setState(() => _provider = v ?? 'supabase'),
          ),
          const SizedBox(height: 14),

          if (isTurso) ...[
            _buildTursoGuide(),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tursoUrlCon,
              decoration: const InputDecoration(
                labelText: 'URL de la base de datos Turso',
                hintText: 'libsql://db-name-org.turso.io',
                prefixIcon: Icon(Icons.link_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tursoTokenCon,
              obscureText: !_showTursoToken,
              decoration: InputDecoration(
                labelText: 'API Token Turso (de Settings → API Tokens)',
                hintText: 'eyJhbGciOi...',
                helperText: 'La app generará automáticamente un Database Token desde este token',
                helperMaxLines: 2,
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                suffixIcon: IconButton(
                  icon: Icon(_showTursoToken ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _showTursoToken = !_showTursoToken),
                ),
              ),
            ),
          ] else ...[
            TextFormField(
              controller: _urlCon,
              decoration: InputDecoration(
                labelText: 'URL del servidor',
                hintText: 'https://tu-proyecto.supabase.co',
                prefixIcon: Icon(Icons.link_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _apiKeyCon,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'API Key (service_role)',
                hintText: 'eyJhbGciOi...',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _anonKeyCon,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Anon Key (opcional)',
                hintText: 'eyJhbGciOi...',
                prefixIcon: Icon(Icons.key_outlined),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing || _syncing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.wifi_find_outlined),
                  label: const Text('Probar conexión'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _syncing ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text('Sincronización automática', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Switch(
                value: _autoSync,
                onChanged: _syncing ? null : (v) => setState(() => _autoSync = v),
              ),
            ],
          ),
          if (_autoSync) ...[
            const SizedBox(height: 10),
            Text('Intervalo: cada $_interval minutos', style: Theme.of(context).textTheme.bodySmall),
            Slider(
              value: _interval.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: '$_interval min',
              onChanged: _syncing ? null : (v) => setState(() => _interval = v.round()),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _syncing ? null : _syncNow,
              icon: _syncing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync_outlined),
              label: Text(_syncing ? 'Sincronizando...' : 'Sincronizar ahora'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
              onPressed: _syncing ? null : _restore,
              icon: const Icon(Icons.restore_page_outlined),
              label: const Text('Restaurar desde remoto'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showInfo,
              icon: const Icon(Icons.info_outline),
              label: const Text('¿Cómo funciona la sincronización?'),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sincronización y Restauración'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoSection('Proveedores soportados', [
                'Supabase — Base de datos PostgreSQL con API REST',
                'Turso (libSQL) — Base de datos SQLite en la nube con API HTTP',
                'Servidor propio — Cualquier API REST que acepte JSON',
              ]),
              _infoSection('¿Cómo funciona la sincronización?', [
                '1. Lee todos los datos locales (transacciones, contactos, configuraciones)',
                '2. Los envía al servidor uno por uno con reintentos automáticos',
                '3. Cada tabla se sube por separado con barra de progreso',
                '4. Si falla, reintenta hasta 3 veces con espera progresiva',
                '5. Guarda la fecha y estado de la última sincronización',
              ]),
              _infoSection('¿Cómo funciona la restauración?', [
                '1. Descarga TODOS los datos del servidor',
                '2. Limpia la base de datos local',
                '3. Inserta los datos descargados en orden',
                '4. Requiere 3 pasos de confirmación:',
                '   • Confirmación inicial',
                '   • Validación humana (operación matemática)',
                '   • Contraseña del usuario',
              ]),
              _infoSection('Sincronización automática', [
                'Si está activada, sincroniza en segundo plano cada N minutos.',
                'Se puede configurar entre 5 y 120 minutos.',
              ]),
              _infoSection('Manejo de errores', [
                'Cada operación HTTP se reintenta hasta 3 veces.',
                'Si falla, se guarda el error en el estado de sincronización.',
                'Puedes volver a intentar manualmente cuando quieras.',
              ]),
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Widget _buildTursoGuide() {
    final s = Theme.of(context).colorScheme;
    return Card(
      color: s.tertiaryContainer.withValues(alpha: 0.3),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: s.tertiary),
                const SizedBox(width: 8),
                Text('Configurar Turso', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            _step(1, 'Ir a app.turso.tech e iniciar sesión'),
            _step(2, 'Crear un database desde el dashboard ("Create Database")'),
            _step(3, 'Ir a Settings → API Tokens → "Create Token". Asignar scopes: db:configure, db:create, db:mint-token, read. Copiar el token (se muestra una sola vez)'),
            _step(4, 'Volver a Databases, abrir el database creado y copiar la URL (empieza con libsql://)'),
            _step(5, 'Pegar la URL y el token en los campos de abajo y presionar "Probar Conexión"'),
          ],
        ),
      ),
    );
  }

  Widget _step(int num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text('$num.', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _infoSection(String title, List<String> lines) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...lines.map((l) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(l, style: Theme.of(context).textTheme.bodySmall),
          )),
        ],
      ),
    );
  }
}
