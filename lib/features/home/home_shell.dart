import 'package:flutter/material.dart';
import 'package:gastos_erp_tracker/core/services/auth_service.dart';
import 'package:gastos_erp_tracker/features/admin/admin_list_screen.dart';
import 'package:gastos_erp_tracker/features/analytics/analytics_dashboard_screen.dart';
import 'package:gastos_erp_tracker/features/analytics/monthly_close_screen.dart';
import 'package:gastos_erp_tracker/features/auth/login_screen.dart';
import 'package:gastos_erp_tracker/features/auth/sync_config_screen.dart';
import 'package:gastos_erp_tracker/features/contacts/contacts_screen.dart';
import 'package:gastos_erp_tracker/features/history/smart_history_screen.dart';
import 'package:gastos_erp_tracker/features/transactions/transaction_form_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 2;
  int _refreshVersion = 0;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar sesión')),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ));
      }
    }
  }

  Future<void> _pushAdmin(Widget screen) async {
    Navigator.pop(context);
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() => _refreshVersion++);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TransactionFormScreen(key: ValueKey('txn_$_refreshVersion'), parentScaffoldKey: _scaffoldKey),
      SmartHistoryScreen(parentScaffoldKey: _scaffoldKey),
      AnalyticsDashboardScreen(parentScaffoldKey: _scaffoldKey),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_circle_outline), label: 'Registrar'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Balance'),
        ],
      ),
      floatingActionButton: _index == 0
          ? null
          : FloatingActionButton.small(
              onPressed: () => setState(() => _index = 0),
              child: const Icon(Icons.add_circle_outline),
            ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer),
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: AuthService.currentUser(),
                  builder: (context, snap) {
                    final user = snap.data;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            (user?['name'] as String? ?? 'U')[0].toUpperCase(),
                            style: TextStyle(fontSize: 22, color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(user?['name'] as String? ?? 'Usuario', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        Text(user?['email'] as String? ?? '', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    );
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Contactos'),
                subtitle: const Text('Clientes, proveedores, obreros'),
                onTap: () => _pushAdmin(const ContactsScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Historial'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _index = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Balance'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _index = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Cierre de Mes'),
                subtitle: const Text('Declaraciones mensuales'),
                onTap: () => _pushAdmin(const MonthlyCloseScreen()),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 4),
                child: Text('ADMINISTRACIÓN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
              ListTile(
                leading: const Icon(Icons.percent_outlined),
                title: const Text('Tasas de IVA'),
                onTap: () => _pushAdmin(const AdminListScreen(
                  table: 'iva_rates',
                  title: 'Tasas de IVA',
                  labelField: 'name',
                  showRate: true,
                )),
              ),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Proyectos'),
                onTap: () => _pushAdmin(const AdminListScreen(
                  table: 'projects',
                  title: 'Proyectos',
                  labelField: 'name',
                )),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Motivos / Categorías'),
                onTap: () => _pushAdmin(const AdminListScreen(
                  table: 'motives',
                  title: 'Motivos',
                  labelField: 'name',
                  showIcon: true,
                )),
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Métodos de pago'),
                onTap: () => _pushAdmin(const AdminListScreen(
                  table: 'payment_methods',
                  title: 'Métodos de pago',
                  labelField: 'name',
                  showIcon: true,
                )),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Tasas de Retención'),
                onTap: () => _pushAdmin(const AdminListScreen(
                  table: 'retention_rates',
                  title: 'Tasas de Retención',
                  labelField: 'name',
                  showRate: true,
                  extraFields: ['type'],
                )),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('Sincronización en la nube'),
                onTap: () => _pushAdmin(const SyncConfigScreen()),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Acerca de'),
                onTap: () {
                  Navigator.pop(context);
                  _showAbout();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_outlined),
                title: const Text('Cerrar sesión'),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Acerca de'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('CoDevNexus & Proyecto Social', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'CoDevNexus es un emprendimiento tecnológico fundado por José Mejía, '
                'enfocado en la creación de soluciones digitales y optimización estratégica. '
                'En un esfuerzo conjunto con el Grupo Número 1 de Vinculación con la Sociedad '
                'de la Universidad ECOTEC, se ha desarrollado esta aplicación móvil como una '
                'herramienta práctica orientada al fortalecimiento del sector emprendedor.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Problemática Financiera', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'En el ecosistema económico actual, un alto porcentaje de microempresarios '
                'y nuevos emprendedores gestionan sus finanzas de manera empírica, usando '
                'registros manuales o herramientas poco accesibles. La falta de un control '
                'diario y centralizado genera desorganización en flujos de caja, dificultad '
                'para visualizar la rentabilidad real y pérdida de oportunidades.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Nuestra Solución', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Aplicación móvil de control financiero que permite registrar gastos diarios, '
                'gestionar compras a proveedores y controlar pagos pendientes, con toda la '
                'información siempre al alcance de la mano.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Aportación Social (Sin Fines Lucrativos)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Este proyecto ha sido concebido bajo principios de desarrollo comunitario '
                'y responsabilidad social. La aplicación es de USO COMPLETAMENTE LIBRE Y SIN '
                'FINES LUCRATIVOS. Nuestro objetivo es proveer una herramienta tecnológica '
                'gratuita que reduzca la brecha digital y apoye la autogestión de emprendedores.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Participantes (Grupo #1)', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Estudiantes:\n'
                '• Jose Luis Mejía Plúas (Líder CoDevNexus)\n'
                '• Nelson Fabricio Bodero Pin\n'
                '• Alex Elias Huacón Diaz\n'
                '• Victor Vergara Monserrate\n'
                '• Fernando Eduardo Rivadeneira Campodónico\n\n'
                'Docente Tutor:\n'
                '• Maria Alexandra Ordoñez Carrera',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Text('Canales oficiales', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Sitio Web: https://codevnexus.tech\n'
                'Soporte: jmejia@codevnexus.tech\n'
                'Entidad: Universidad ECOTEC - Vinculación con la Sociedad',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}
