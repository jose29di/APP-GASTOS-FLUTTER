# AGENTS.md — gastos_erp_tracker (Control de Gastos)

## Project Vision

A Material 3 mobile expense/income tracker for independent contractors, specialists, and builders in Ecuador/LATAM. It serves as a pocket financial ERP and tax management tool that balances **official tax compliance** (invoices, withholding taxes — facturas, retenciones) with **true cash flow visibility** (informal outlays, daily worker payouts without invoices, personal vs. business tracking).

### Design Principles
- **Minimalist, scannable Material 3** with full light/dark mode support.
- **Accent colors distinguish financial states**: green for incomes, red/orange for expenses, violet for advances.
- **Bold typography** for monetary metrics; clean sans-serif throughout.
- **Two parallel accounting views**: *Caja Real* (true cash flow) vs. *Balance Tributario* (tax-scope only).
- **Offline-first**: all data stored locally in SQLite; cloud sync is optional.

---

## Current Architecture (Flutter, no state management library yet)

```
lib/
├── main.dart                                  # Entry point, runApp(ExpenseErpApp) — sin debug prints
├── app.dart                                   # MaterialApp + SplashScreen (auth gate) — sin debug prints
├── core/
│   ├── database/
│   │   ├── app_database.dart                  # SQLite singleton (sqflite helper)
│   │   └── schema.dart                        # DDL: users, contacts, transactions, retentions, audit_log, sync_config, user_permissions
│   ├── services/
│   │   ├── auth_service.dart                  # Register/login/logout with sha256 + SharedPreferences + FlutterSecureStorage
│   │   ├── audit_service.dart                 # Audit trail (CREATE/UPDATE/DELETE per entity)
│   │   ├── export_service.dart                # Export to XLS (Excel) con datos completos de contacto + columna Tributa
│   │   └── sync_service.dart                  # SyncConfig model + SyncService (Supabase REST push)
│   ├── theme/
│   │   ├── app_colors.dart                    # Seed, income (green), expense (red), amber, blue, violet (advances)
│   │   └── app_theme.dart                     # Material 3 ThemeData factory (light + dark)
│   └── utils/
│       └── money_formatter.dart               # currency(num) → "$X,XXX.XX"
├── domain/
│   └── models/
│       └── transaction_record.dart            # Legacy model (kept for reference)
├── features/
│   ├── analytics/
│   │   ├── models/
│   │   │   └── chart_segment.dart             # Color + value + optional label
│   │   ├── analytics_dashboard_screen.dart    # Toggle Caja Real/Tributario, KPIs, donut, bar, thresholds — lee de SQLite
│   │   ├── monthly_close_screen.dart          # Cierre mensual con exportación Excel
│   │   └── widgets/
│   │       ├── bar_comparison_chart.dart       # CustomPainter: deductible vs. non-deductible
│   │       ├── chart_panel.dart               # Card wrapper with title
│   │       ├── donut_chart.dart               # CustomPainter: rounded-stroke donut
│   │       ├── kpi_card.dart                  # Icon + label + bold value
│   │       ├── legend_dot.dart                # Colored dot + label + value
│   │       └── threshold_progress.dart        # LinearProgressIndicator + label + amount
│   ├── auth/
│   │   ├── login_screen.dart                  # Login/Register with email+password, session persistence
│   │   └── sync_config_screen.dart            # Cloud sync config (Supabase): URL, API key, auto-sync interval, manual sync button
│   ├── contacts/
│   │   └── contacts_screen.dart               # CRUD contactos (Cliente/Proveedor/Obrero) + ContactFormScreen
│   ├── history/
│   │   ├── smart_history_screen.dart          # CustomScrollView + slivers, grouped by date, lee de SQLite
│   │   └── widgets/
│   │       ├── date_header.dart               # Date group title (bold)
│   │       ├── filter_header_delegate.dart    # Sticky search bar + category chips + project filter
│   │       └── transaction_card.dart          # Card: icon, vendor, amount, project, note, status badges (Con/Sin Factura, credit, pending/paid)
│   ├── home/
│   │   └── home_shell.dart                    # NavigationBar (3 tabs) + drawer (contacts, sync config, logout)
│   └── transactions/
│       ├── transaction_form_screen.dart       # 3-way toggle (Ingreso/Egreso/Anticipo), monto, proyecto, contacto, scope (business/personal), payment, invoice toggle, credit+due date, retenciones anidadas (Fuente + IVA + Serv. Prof.), net cash footer, guarda en SQLite + audit
│       └── widgets/
│           ├── amount_input.dart              # Large display-small input with $ prefix
│           ├── output_badge.dart              # Read-only retention value badge
│           └── tax_sub_form.dart              # Base IVA / Base Tarifa 0%, retention rate chips (Fuente + IVA + Serv. Prof.), calculated output badges
└── shared/
    └── widgets/
        ├── horizontal_choice_chips.dart       # Horizontal scrolling ChoiceChip row with optional leading icons
        ├── labeled_field.dart                 # SectionTitle + child column
        ├── section_title.dart                 # Bold labelLarge styled text
        └── status_badge.dart                  # Small chip with icon + label (e.g. "Con Factura", "Sin Factura")
```

### Cross-cutting decisions
- **No external state management** yet — all state is local `setState`. Ready for Riverpod/Bloc when scale demands it.
- **SQLite first (sqflite)** — all data persisted locally. Cloud sync is optional via Supabase REST API.
- **Auth**: local with sha256 password hashing, session stored in SharedPreferences + FlutterSecureStorage.
- **Audit trail**: all CREATE/UPDATE/DELETE logged in `audit_log` table with user_id, old/new JSON values.
- **Multi-user**: each record tagged with `owner_id`. Users can have permissions to read/write others' data.
- **Retentions**: stored in separate `retentions` table, each transaction can have multiple (Fuente, IVA, Servicios Profesionales).
- **All charts are `CustomPainter`** — no chart library dependency.
- **Material 3** via `ColorScheme.fromSeed` — dynamic theming from a single seed color.
- **Spanish UI** — all labels, categories, and messages are in Spanish (Ecuadorian context).
- **Use `.withValues(alpha: ...)`** instead of deprecated `.withOpacity(...)`.
- **Excel export**: uses `excel ^4.0.0` package, cell-by-cell `sheet.cell(CellIndex.indexByColumnRow(...)).value` (NOT `appendRow` which has bugs with this package version).

---

## Development Commands

```bash
# Comando de Regeneración Automatizada
flutter create .

# Run app
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze

# Limpia los archivos de compilación
flutter clean

# Obtén de nuevo las dependencias:
flutter pub get

# Recrear plataformas específicas
Android: flutter create --platforms=android .
iOS: flutter create --platforms=ios .
Web: flutter create --platforms=web .

# Generar iconos de aplicación (requiere assets/icon/icon.png 1024x1024)
flutter pub run flutter_launcher_icons

# Build Android APK (release)
flutter build apk --release

# Build Android AppBundle (recomendado para Google Play)
flutter build appbundle --release

# Build iOS (requiere macOS)
flutter build ios --release
```

---

## Google Play Config

- **Application ID**: `com.codevnexus.appgastos`
- **App name**: Control de Gastos
- **Version**: `1.0.0+1` (pubspec.yaml)
- **minSdk**: 21
- **targetSdk**: Flutter target (34+)
- **Keystore**: `android/app/upload-keystore.jks` (alias `upload`, password `30553055` — CAMBIAR para producción)
- **Signing config**: `android/key.properties` (ambos archivos en `.gitignore`)
- **Splash**: verde `#1B6B4A` en `android/app/src/main/res/drawable/launch_background.xml`
- **Iconos**: generados con `flutter_launcher_icons` desde `assets/icon/icon.png`
- **R8/ProGuard**: deshabilitado (`isMinifyEnabled = false`, `isShrinkResources = false`) porque causa crash al inicio (Flutter engine classes missing). Re-activar solo con keep rules correctas.
- **Dependencia extra**: `com.google.android.play:core:1.10.3` para evitar `Missing classes` en build release.

### Android files structure
- `android/app/src/main/kotlin/com/codevnexus/appgastos/MainActivity.kt` — package `com.codevnexus.appgastos`
- `android/app/src/main/AndroidManifest.xml` — label "Control de Gastos", INTERNET permission, allowBackup, supportsRtl
- `android/app/build.gradle.kts` — applicationId, signing config, minSdk 21, play-core dependency
- `android/app/proguard-rules.pro` — keep rules for Flutter engine, sqflite, flutter_secure_storage, play-core

### Windows build note
Flutter en Windows requiere Developer Mode activado o variable:
```powershell
$env:FLUTTER_BUILD_SYMLINK = "false"
```

---

## Auth State

### ✅ Implementado
- **Registro**: usuarios guardados en SQLite con contraseña hasheada (SHA-256)
- **Login**: validación contra DB, sesión guardada en `SharedPreferences` + `FlutterSecureStorage`
- **Sesión**: token único con timestamp, expira a los 30 días
- **Validación de sesión**: `validateSession()` verifica que el usuario aún exista y esté activo en DB
- **SplashScreen**: verifica sesión al iniciar, muestra error con botón reintentar si falla DB
- **Contraseñas**: mínimo 4 chars para login, 6 para registro, hash SHA-256
- **Logout**: limpia prefs + secure storage
- **Multi-dispositivo**: cada usuario tiene datos independientes (`owner_id` en cada registro)
- **Sincronización**: todos los usuarios se suben junto con transacciones y contactos

---

## Export to Excel (`export_service.dart`)

- Exporta **todos** los registros (sin filtro año/mes)
- Columnas: Tipo, Fecha, Monto, Contacto, CI/RUC, Categoría, Teléfono, Email, Proyecto, Nota, Factura (Sí/No), Crédito, Vencimiento, Tributa (Sí/No basado en `scope`), Estado
- **No usa `appendRow`** — escribe celda por celda con `sheet.cell(CellIndex.indexByColumnRow(...)).value`
- Elimina la hoja "Sheet1" por defecto
- Nombre de archivo: `Gastos_YYYY-MM-DD_HHmmss.xlsx`

---

## Critical Context (historial de sesiones)

### Sesión actual (signed APK + release build)
- Se cambió `applicationId` de `com.example.gastos_erp_tracker` → `com.codevnexus.appgastos`
- Se movió `MainActivity.kt` al directorio `com/codevnexus/appgastos/` con package actualizado (corrige ClassNotFoundException)
- Se eliminó el directorio viejo `com/example/`
- Se creó `upload-keystore.jks` y `key.properties`
- Se agregó signing config en `build.gradle.kts`
- Se deshabilitó minification (R8/ProGuard) porque causaba crash
- Se agregó `play-core` dependency para build release
- Se generaron iconos adaptativos con `flutter_launcher_icons`
- Splash background verde `#1B6B4A`
- APK release construido exitosamente (57.7 MB)
- Se removieron todos los `print()` de depuración de `main.dart` y `app.dart`
- `flutter analyze` pasa sin errores

### Sesión anterior (export_service)
- Se corrigió exportación XLS: ahora usa cell-by-cell en vez de `appendRow`
- Se agregó columna "Tributa" (Sí/No según scope business/personal)
- Se resuelven datos completos de contacto (nombre, CI/RUC, categoría, teléfono, email)
- Se eliminó la hoja "Sheet1" por defecto del archivo Excel

---

## Next Steps / Roadmap

1. ✅ **Login/Auth** — registro + inicio sesión con persistencia
2. ✅ **SQLite local** — esquema completo con usuarios, transacciones, contactos, retenciones, auditoría
3. ✅ **Formulario mejorado** — 3 tipos (ingreso/egreso/anticipo), crédito, retenciones múltiples, scope business/personal
4. ✅ **Contactos CRUD** — clientes, proveedores, obreros
5. ✅ **Configuración de sincronización** — Supabase con URL, API key, sync manual/automático
6. ✅ **Exportación a Excel** — XLS con datos completos de contacto + columna Tributa
7. ✅ **Release APK firmado** — icons, splash, signing config, Google Play ready
8. 🔲 **Sincronización real** — implementar lógica de sync bidireccional (pull + merge)
9. 🔲 **Cuentas por Pagar y Anticipos** — dashboard de facturas vencidas, anticipos activos
10. 🔲 **Notificaciones de vencimiento** — recordatorios para facturas por vencer
11. 🔲 **Permisos multi-usuario** — pantalla de administración de permisos entre usuarios
12. 🔲 **Reportes PDF** — exportar balance tributario y caja real
13. 🔲 **Escáner de documentos** — OCR para captura de facturas
14. 🔲 **Re-activar R8/ProGuard** con keep rules correctas para reducir tamaño APK
15. 🔲 **Cambiar keystore password** a una segura antes de publicación

---

## Coding Conventions
- Use `const` constructors where possible.
- Prefer `CustomPainter` over third-party chart libraries (current approach).
- Keep widgets small and single-purpose.
- Spanish for all user-facing strings.
- `currency()` from `money_formatter.dart` for all monetary display.
- All DB operations go through `AppDatabase` helper class.
- All auth operations through `AuthService`.
- Audit every data mutation via `AuditService.log()`.
- No `print()` statements in release code.
- Excel: use `sheet.cell(CellIndex.indexByColumnRow(...)).value`, never `appendRow`.
