-- ================================================================
-- PARFUM — Script de base de datos MySQL
-- Ejecutar: mysql -u root -p < parfum_db.sql
-- ================================================================

CREATE DATABASE IF NOT EXISTS parfum_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE parfum_db;

-- ── Usuarios (todos los roles) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  nombre           VARCHAR(100)  NOT NULL,
  email            VARCHAR(100)  NOT NULL UNIQUE,
  hashed_password  VARCHAR(255)  NOT NULL,
  rol              ENUM('gerente','cajero','almacenista','cliente') DEFAULT 'cliente',
  rfc              VARCHAR(20)   NULL,
  telefono         VARCHAR(20)   NULL,
  estado           VARCHAR(20)   DEFAULT 'activo',
  fecha_registro   DATETIME      DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_rol   (rol)
);

-- ── Productos ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  sku             VARCHAR(30)   NOT NULL UNIQUE,
  nombre          VARCHAR(150)  NOT NULL,
  descripcion     TEXT          NULL,
  categoria       VARCHAR(50)   NOT NULL,
  concentracion   VARCHAR(10)   NOT NULL,
  ml              INT           NOT NULL,
  precio          DECIMAL(10,2) NOT NULL,
  stock           INT           DEFAULT 0,
  estado          ENUM('disponible','bajo_stock','sin_stock','inactivo') DEFAULT 'disponible',
  imagen_url      VARCHAR(500)  NULL,
  fecha_registro  DATETIME      DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_sku       (sku),
  INDEX idx_categoria (categoria),
  INDEX idx_estado    (estado)
);

-- ── Pedidos (clientes en línea) ───────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT           NOT NULL,
  fecha        DATETIME      DEFAULT CURRENT_TIMESTAMP,
  total        DECIMAL(10,2) NOT NULL,
  status       VARCHAR(50)   DEFAULT 'Pendiente',
  metodo_pago  VARCHAR(50)   NULL,
  referencia   VARCHAR(100)  NULL,
  banco        VARCHAR(100)  NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE RESTRICT,
  INDEX idx_user_id (user_id),
  INDEX idx_status  (status)
);

-- ── Ítems de pedido ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_items (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  order_id        INT           NOT NULL,
  producto_id     INT           NOT NULL,
  cantidad        INT           NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (order_id)    REFERENCES orders(id)   ON DELETE CASCADE,
  FOREIGN KEY (producto_id) REFERENCES products(id) ON DELETE RESTRICT
);

-- ── Ventas en caja física ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sales (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  cajero_id       INT           NOT NULL,
  fecha           DATETIME      DEFAULT CURRENT_TIMESTAMP,
  subtotal        DECIMAL(10,2) NOT NULL,
  iva             DECIMAL(10,2) NOT NULL,
  total           DECIMAL(10,2) NOT NULL,
  metodo_pago     VARCHAR(50)   NOT NULL,
  monto_recibido  DECIMAL(10,2) NOT NULL,
  cambio          DECIMAL(10,2) DEFAULT 0,
  FOREIGN KEY (cajero_id) REFERENCES users(id) ON DELETE RESTRICT,
  INDEX idx_cajero_id (cajero_id),
  INDEX idx_fecha     (fecha)
);

-- ── Ítems de venta ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sale_items (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  sale_id         INT           NOT NULL,
  producto_id     INT           NOT NULL,
  cantidad        INT           NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (sale_id)     REFERENCES sales(id)    ON DELETE CASCADE,
  FOREIGN KEY (producto_id) REFERENCES products(id) ON DELETE RESTRICT
);

-- ── Carrito (persistido por usuario) ─────────────────────────────
CREATE TABLE IF NOT EXISTS cart_items (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  user_id     INT NOT NULL,
  producto_id INT NOT NULL,
  cantidad    INT DEFAULT 1,
  FOREIGN KEY (user_id)     REFERENCES users(id)    ON DELETE CASCADE,
  FOREIGN KEY (producto_id) REFERENCES products(id) ON DELETE CASCADE,
  UNIQUE KEY uq_user_product (user_id, producto_id)
);

-- ================================================================
-- DATOS INICIALES
-- ================================================================

-- Gerente por defecto (password: Admin123)
-- bcrypt hash de "Admin123"
INSERT IGNORE INTO users (nombre, email, hashed_password, rol, estado)
VALUES (
  'Gerente Principal',
  'gerente@parfum.mx',
  '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMaVbNLFphOXaqTMDhKCJdNlKS',
  'gerente',
  'activo'
);

-- Cajero de prueba (password: Cajero123)
INSERT IGNORE INTO users (nombre, email, hashed_password, rol, rfc, estado)
VALUES (
  'Carlos López Martínez',
  'cajero@parfum.mx',
  '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW',
  'cajero',
  'LOMC900101ABC',
  'activo'
);

-- Almacenista de prueba (password: Almacen123)
INSERT IGNORE INTO users (nombre, email, hashed_password, rol, rfc, estado)
VALUES (
  'Ana Martínez Ruiz',
  'almacen@parfum.mx',
  '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeG6Lruj3vjPGga31lW',
  'almacenista',
  'MARA850215XYZ',
  'activo'
);

-- Productos de ejemplo
INSERT IGNORE INTO products (sku, nombre, descripcion, categoria, concentracion, ml, precio, stock, estado)
VALUES
  ('CH-001', 'Chanel No. 5',        'El perfume más icónico del mundo. Notas de ylang-ylang y jazmín.', 'Mujer',  'EDP', 100, 3500.00, 15, 'disponible'),
  ('DI-002', 'Dior Sauvage',        'Fresco y viril. Notas de bergamota y pimienta de Sichuan.',        'Hombre', 'EDT', 100, 2800.00, 20, 'disponible'),
  ('GC-003', 'Good Girl',           'Seductor y sofisticado. Notas de jazmín y cacao.',                 'Mujer',  'EDP',  80, 3200.00,  8, 'disponible'),
  ('BL-004', 'Bleu de Chanel',      'Elegante y moderno. Notas cítricas y maderosas.',                  'Hombre', 'EDP', 100, 3100.00, 12, 'disponible'),
  ('JA-005', 'Jean Paul Gaultier',  'Icónico y provocador. Notas de vainilla y jengibre.',              'Mujer',  'EDT',  50, 1900.00,  4, 'bajo_stock'),
  ('UN-006', 'CK One',              'Fresco y libre. Notas cítricas y de musgo de roble.',              'Unisex', 'EDT', 200, 1200.00, 30, 'disponible'),
  ('AC-007', 'Acqua di Gio',        'Marino y fresco. Evoca el Mediterráneo.',                          'Hombre', 'EDT', 100, 2400.00, 18, 'disponible'),
  ('LV-008', 'La Vie Est Belle',    'Optimista y femenino. Notas de iris y pralinéhel.',                'Mujer',  'EDP',  75, 2700.00,  6, 'disponible');
