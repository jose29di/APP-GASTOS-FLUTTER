class Schema {
  Schema._();

  static const int version = 6;

  static String get createTables => '''
CREATE TABLE IF NOT EXISTS retention_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  rate REAL NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  avatar_url TEXT,
  role TEXT NOT NULL DEFAULT 'user',
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS contacts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  identification TEXT,
  category TEXT NOT NULL DEFAULT 'cliente',
  phone TEXT,
  email TEXT,
  is_recurring INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (owner_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  owner_id INTEGER NOT NULL,
  contact_id INTEGER,
  type TEXT NOT NULL DEFAULT 'expense',
  amount REAL NOT NULL,
  category TEXT NOT NULL,
  project TEXT,
  scope TEXT NOT NULL DEFAULT 'business',
  payment_method TEXT NOT NULL DEFAULT 'Efectivo',
  has_invoice INTEGER NOT NULL DEFAULT 0,
  factura_number TEXT,
  iva_base REAL NOT NULL DEFAULT 0,
  zero_base REAL NOT NULL DEFAULT 0,
  is_credit INTEGER NOT NULL DEFAULT 0,
  due_date TEXT,
  is_paid INTEGER NOT NULL DEFAULT 0,
  paid_amount REAL,
  paid_date TEXT,
  vendor TEXT,
  notes TEXT,
  related_transaction_id INTEGER,
  date TEXT NOT NULL DEFAULT (datetime('now')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (owner_id) REFERENCES users(id),
  FOREIGN KEY (contact_id) REFERENCES contacts(id),
  FOREIGN KEY (related_transaction_id) REFERENCES transactions(id)
);

CREATE TABLE IF NOT EXISTS retentions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transaction_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  base_amount REAL NOT NULL,
  rate REAL NOT NULL,
  value REAL NOT NULL,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

CREATE TABLE IF NOT EXISTS audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id INTEGER NOT NULL,
  old_values TEXT,
  new_values TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS sync_config (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  provider TEXT NOT NULL DEFAULT 'supabase',
  server_url TEXT,
  api_key TEXT,
  anon_key TEXT,
  turso_url TEXT,
  turso_token TEXT,
  auto_sync INTEGER NOT NULL DEFAULT 0,
  sync_interval_minutes INTEGER NOT NULL DEFAULT 15,
  last_sync_at TEXT,
  last_sync_status TEXT,
  is_enabled INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_permissions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  target_user_id INTEGER NOT NULL,
  can_read INTEGER NOT NULL DEFAULT 1,
  can_write INTEGER NOT NULL DEFAULT 0,
  can_delete INTEGER NOT NULL DEFAULT 0,
  request_password TEXT,
  expires_at TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (target_user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS iva_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  rate REAL NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS motives (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS payment_methods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
''';

  static String get migrationV1ToV2 => '''
ALTER TABLE transactions ADD COLUMN factura_number TEXT;
CREATE TABLE IF NOT EXISTS iva_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  rate REAL NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS projects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS motives (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS payment_methods (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  icon TEXT,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS retention_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  rate REAL NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
''';

  static String get migrationV2ToV3 => '''
CREATE TABLE IF NOT EXISTS retention_rates (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type TEXT NOT NULL,
  name TEXT NOT NULL,
  rate REAL NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
''';

  static String get migrationV3ToV4 => '''
ALTER TABLE sync_config ADD COLUMN turso_url TEXT;
ALTER TABLE sync_config ADD COLUMN turso_token TEXT;
''';

  static String get migrationV4ToV5 => '''
ALTER TABLE transactions ADD COLUMN paid_amount REAL;
''';

  static String get migrationV5ToV6 => '''
ALTER TABLE transactions ADD COLUMN vendor TEXT;
''';
}
