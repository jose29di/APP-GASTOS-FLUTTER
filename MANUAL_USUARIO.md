# Manual de Usuario — Gestión de Gastos e Ingresos para Contribuyentes Independientes

## Proyecto de Vinculación con la Sociedad

---

## 1. Introducción

**Gastos ERP Tracker** es una aplicación móvil diseñada para profesionales independientes, albañiles, técnicos especialistas y pequeños contribuyentes en Ecuador y Latinoamérica. Su objetivo es facilitar el control de ingresos y gastos diarios, permitiendo llevar una contabilidad clara que distinga entre lo que se declara ante el SRI (transacciones tributarias) y el flujo de caja real (incluyendo gastos informales sin factura).

La aplicación nace de la necesidad observada en comunidades de trabajadores independientes que:
- No tienen acceso a software contable profesional.
- Manejan una mezcla de ingresos formales (con factura) e informales (sin respaldo documental).
- Necesitan saber cuánto destinar a impuestos y retenciones (Fuente, IVA, Servicios Profesionales).
- Requieren un registro sencillo de anticipos y créditos otorgados a clientes o trabajadores.

---

## 2. Objetivos del Proyecto

1. **Educación financiera**: Proveer una herramienta que enseñe al usuario la diferencia entre caja real y balance tributario.
2. **Formalización**: Incentivar el registro de transacciones con y sin factura para tener visibilidad completa de las finanzas.
3. **Cumplimiento tributario**: Ayudar al contribuyente a calcular bases imponibles (IVA, Tarifa 0%) y retenciones aplicables.
4. **Accesibilidad**: Funcionar completamente offline, sin necesidad de conexión a internet ni suscripciones.
5. **Portabilidad**: Disponible en dispositivos Android e iOS, siempre en el bolsillo del usuario.

---

## 3. Funcionalidades Principales

### 3.1 Autenticación y Seguridad
- **Registro de usuario**: Creación de cuenta con correo electrónico y contraseña (mínimo 6 caracteres).
- **Inicio de sesión**: Acceso seguro con validación local.
- **Persistencia de sesión**: La sesión permanece activa por 30 días; no es necesario iniciar sesión cada vez.
- **Multi-usuario**: Cada usuario tiene sus propios datos financieros, aislados de los demás.
- **Cierre de sesión**: Elimina todos los datos de sesión del dispositivo.

### 3.2 Registro de Transacciones

La aplicación permite registrar tres tipos de movimientos:

| Tipo | Icono | Descripción | Ejemplos |
|------|-------|-------------|----------|
| **Ingreso** | ↓ Verde | Dinero que ingresa al negocio | Cobro de honorarios, venta de productos, pago de facturas |
| **Egreso** | ↑ Rojo | Dinero que sale del negocio | Compra de materiales, pago a obreros, servicios básicos |
| **Anticipo** | ◷ Violeta | Adelantos de dinero | Anticipo a proveedor, préstamo a empleado, adelanto de cliente |

**Campos del formulario**:

- **Tipo**: Ingreso, Egreso o Anticipo (selector de tres posiciones).
- **Monto**: Valor numérico de la transacción (formato moneda $X,XXX.XX).
- **Categoría**: Clasificación del gasto/ingreso (Materiales, Mano de obra, Transporte, Alimentación, Servicios, etc.).
- **Proyecto**: Nombre del proyecto u obra asociada.
- **Ámbito**: **Trabajo** (negocio, tributario) o **Personal** (gastos personales, no tributarios).
- **Método de pago**: Efectivo, Transferencia, Tarjeta, Cheque, etc.
- **Contacto**: Cliente, proveedor u obrero asociado (opcional).
- **N° Factura**: Número de factura o documento de respaldo.
- **Bases tributarias**:
  - *Base IVA*: Monto gravado con IVA.
  - *Base Tarifa 0%*: Monto exento de IVA.
- **Retenciones**: Configuración de retenciones aplicables (Fuente, IVA, Servicios Profesionales) con selección de tasa y cálculo automático.
- **Crédito**: Indica si la transacción está pendiente de cobro/pago, con fecha de vencimiento.
- **Estado de pago**: Pagado o Pendiente, con fecha y monto de pago.

### 3.3 Gestión de Contactos

Registro de personas con las que se realizan transacciones:

- **Cliente**: Persona o empresa que recibe servicios/productos.
- **Proveedor**: Persona o empresa que vende bienes o servicios.
- **Obrero**: Trabajador jornalero o contratado por obra.

**Datos almacenados**: Nombre, identificación (cédula/RUC), teléfono, correo electrónico, notas adicionales.

### 3.4 Historial de Transacciones

- **Listado cronológico**: Todas las transacciones ordenadas por fecha (más recientes primero).
- **Agrupación por fecha**: Separación visual por días.
- **Búsqueda y filtros**: Barra de búsqueda por texto y filtros por categoría y proyecto.
- **Badges de estado**: Indicadores visuales de "Con Factura", "Sin Factura", "Crédito", "Pagado", "Pendiente".
- **Edición y eliminación**: Cada transacción se puede modificar o eliminar con registro de auditoría.

### 3.5 Dashboard de Análisis

- **KPIs principales**: Totales de ingresos, egresos, saldo neto y anticipos del período.
- **Gráfico de dona**: Distribución de gastos por categoría.
- **Gráfico de barras**: Comparación de gastos deducibles vs. no deducibles.
- **Alternancia de vista**: Puede mostrar *Caja Real* (incluye gastos personales e informales) o *Balance Tributario* (solo transacciones de trabajo).
- **Umbrales**: Indicadores visuales de progreso hacia metas financieras.

### 3.6 Cierre de Mes

- **Selección de mes/año**: Permite elegir cualquier período mensual.
- **Resumen mensual**: Ingresos, egresos, anticipos, bases tributarias (IVA y Tarifa 0%).
- **Retenciones**: Totales de retenciones de Fuente, IVA y Servicios Profesionales.
- **Neto del período**: Caja Real (con anticipos) y Balance Tributario (sin anticipos).
- **Exportación a Excel**: Genera un archivo .xlsx con tres hojas:
  1. **Transacciones**: Todos los movimientos con datos completos de contactos.
  2. **Contactos**: Listado completo de contactos registrados.
  3. **Resumen Mensual**: Totales y retenciones del período seleccionado.

### 3.7 Sincronización en la Nube (Opcional)

- **Configuración de Supabase**: Ingreso de URL del proyecto y clave API.
- **Sincronización manual**: Subir datos al servidor cuando se desee.
- **Sincronización automática**: Intervalo programable (cada 15, 30, 60 minutos).
- **Respaldo en la nube**: Todos los datos del usuario se almacenan de forma remota como respaldo.

---

## 4. Arquitectura Técnica

### 4.1 Tecnologías Utilizadas

| Componente | Tecnología |
|------------|------------|
| Framework | Flutter (Dart) |
| Base de datos local | SQLite (sqflite) |
| Almacenamiento seguro | flutter_secure_storage |
| Autenticación | SHA-256 + SharedPreferences |
| Generación de Excel | excel (Dart) |
| Gráficos | CustomPainter (sin librerías externas) |
| Diseño UI | Material Design 3 (Material You) |

### 4.2 Estructura de la Base de Datos

La aplicación utiliza SQLite con las siguientes tablas principales:

- **users**: Almacena las cuentas de usuario con contraseña hasheada.
- **transactions**: Registro de ingresos, egresos y anticipos con todos los detalles financieros y tributarios.
- **contacts**: Directorio de clientes, proveedores y obreros.
- **retentions**: Registro de retenciones aplicadas a cada transacción (Fuente, IVA, Serv. Prof.).
- **audit_log**: Trazabilidad de todas las operaciones (creación, modificación, eliminación).
- **sync_config**: Configuración de sincronización con Supabase.

### 4.3 Principios de Diseño

- **Offline-first**: Todos los datos se almacenan localmente; la nube es opcional.
- **Material You**: Adaptación automática de colores según el tema del sistema (claro/oscuro).
- **Código sin dependencias externas de gráficos**: Los gráficos se dibujan con CustomPainter para evitar librerías pesadas.
- **Idioma español**: Interfaz completamente en español con terminología local (Ecuador).
- **Accesibilidad**: Contraste de colores, tamaños de fuente legibles, iconografía clara.

---

## 5. Guía de Uso Rápido

### 5.1 Primeros Pasos

1. **Instalar la aplicación** en el dispositivo móvil (Android o iOS).
2. **Crear una cuenta**: Abrir la app, presionar "Registrarse", ingresar nombre, correo y contraseña.
3. **Iniciar sesión**: Usar las credenciales creadas.
4. **Configurar contactos** (opcional): Ir al menú lateral > "Contactos" y agregar clientes, proveedores u obreros.

### 5.2 Registrar un Ingreso

1. En la pantalla principal, presionar el botón flotante "+".
2. Seleccionar la pestaña **Ingreso**.
3. Ingresar el **monto** recibido.
4. Seleccionar la **categoría** (Honorarios, Venta de productos, etc.).
5. Indicar el **proyecto** asociado.
6. Elegir el **ámbito**: "Trabajo" si es para declarar, "Personal" si no.
7. Seleccionar el **método de pago** y **contacto** (si aplica).
8. Si tiene factura, activar el interruptor y llenar el número.
9. Ingresar las **bases tributarias** (Base IVA y Base 0%).
10. Si aplican retenciones, configurarlas en la sección correspondiente.
11. Presionar **Guardar**.

### 5.3 Registrar un Gasto

El proceso es similar al ingreso, seleccionando la pestaña **Egreso** e indicando:
- Proveedor o vendedor.
- Categoría del gasto (Materiales, Herramientas, Transporte, etc.).
- Si es un gasto personal o de trabajo.

### 5.4 Registrar un Anticipo

1. Seleccionar la pestaña **Anticipo**.
2. Indicar el **monto** adelantado.
3. Seleccionar **contra quién** se aplica: un contacto existente.
4. El anticipo se registra automáticamente como pagado (no puede ser crédito).

### 5.5 Revisar el Historial

1. En la pantalla principal, presionar la pestaña **Historial** (segundo icono).
2. Las transacciones aparecen agrupadas por fecha.
3. Usar la barra de búsqueda para filtrar.
4. Presionar una transacción para **ver detalles**, **editar** o **eliminar**.

### 5.6 Ver el Dashboard

1. Presionar la pestaña **Balance** (tercer icono).
2. Alternar entre "Caja Real" y "Balance Tributario" con el interruptor superior.
3. Observar los KPIs, gráficos y umbrales.

### 5.7 Generar Informe Mensual

1. Abrir el menú lateral > **Cierre de Mes**.
2. Presionar el encabezado del mes para cambiarlo si es necesario.
3. Revisar el resumen: ingresos, egresos, anticipos, bases tributarias y retenciones.
4. Presionar **Exportar a Excel** para generar un archivo .xlsx.
5. Compartir el archivo por correo, WhatsApp u otro medio.

### 5.8 Cerrar Sesión

1. Abrir el menú lateral.
2. Presionar **Cerrar Sesión** al final del menú.

---

## 6. Glosario

| Término | Definición |
|---------|------------|
| **Caja Real** | Flujo de efectivo real que incluye todas las transacciones, incluso gastos personales e informales. |
| **Balance Tributario** | Sumatoria de ingresos y egresos considerados para declaración de impuestos (solo ámbito Trabajo). |
| **Base IVA** | Monto de la transacción sobre el cual se calcula el IVA (12% en Ecuador). |
| **Base Tarifa 0%** | Monto de la transacción exento de IVA. |
| **Retención en la Fuente** | Porcentaje del valor de la factura retenido por el comprador y entregado al SRI en nombre del vendedor. |
| **Retención de IVA** | Porcentaje del IVA facturado retenido por el comprador. |
| **Anticipo** | Adelanto de dinero entregado o recibido antes de completar un servicio o entrega. |
| **SRI** | Servicio de Rentas Internas, entidad tributaria del Ecuador. |
| **RUC** | Registro Único de Contribuyentes, identificación tributaria en Ecuador. |

---

## 7. Consideraciones Técnicas para Desarrolladores

### 7.1 Requisitos del Sistema
- **Flutter** 3.x o superior.
- **Dart** 3.x o superior.
- **Android** 5.0 (API 21) o superior.
- **iOS** 12.0 o superior.

### 7.2 Comandos de Desarrollo

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run

# Análisis estático de código
flutter analyze

# Ejecutar pruebas
flutter test

# Limpiar archivos de compilación
flutter clean
```

### 7.3 Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── app.dart                     # Configuración de MaterialApp
├── core/
│   ├── database/                # Capa de datos SQLite
│   │   ├── app_database.dart    # Singleton de base de datos
│   │   └── schema.dart          # Definición de esquemas DDL
│   ├── services/                # Servicios (auth, auditoría, sync, exportación)
│   ├── theme/                   # Tema Material 3 (colores + estilos)
│   └── utils/                   # Utilidades (formateo de moneda)
├── features/
│   ├── analytics/               # Dashboard, gráficos, cierre de mes
│   ├── auth/                    # Login, registro, sync config
│   ├── contacts/                # CRUD de contactos
│   ├── history/                 # Historial de transacciones
│   ├── home/                    # Navegación principal (shell)
│   └── transactions/            # Formulario de transacciones
└── shared/
    └── widgets/                 # Widgets reutilizables
```

---

## 8. Conclusiones

**Gastos ERP Tracker** es una herramienta de código abierto que democratiza el acceso al control financiero para pequeños contribuyentes y trabajadores independientes. Al funcionar completamente offline, no requiere conexión a internet ni conocimientos contables avanzados.

Su diseño en español con terminología local (SRI, RUC, factura, retención) la hace accesible para la realidad ecuatoriana y latinoamericana. La distinción entre Caja Real y Balance Tributario permite al usuario entender su verdadera situación financiera mientras cumple con sus obligaciones fiscales.

La exportación a Excel y los reportes mensuales facilitan la entrega de información a contadores o la presentación en proyectos de vinculación con la sociedad.

---

## 9. Licencia

Proyecto de código abierto desarrollado como parte de un proyecto de vinculación con la sociedad. Distribuido bajo licencia MIT.

---

*Documento generado para proyecto de vinculación con la sociedad — 2026*
