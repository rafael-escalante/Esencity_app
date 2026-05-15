# PARFUM — Sistema de Gestión de Perfumería

Proyecto Flutter + FastAPI + MySQL para gestión de perfumería con 4 roles.

---

## Estructura del proyecto

```
parfum/
├── lib/                    ← Flutter app
│   ├── main.dart
│   ├── core/
│   │   ├── constants/      ← Colores, strings, endpoints
│   │   ├── network/        ← Dio + interceptor JWT
│   │   ├── theme/          ← Temas por rol
│   │   ├── utils/          ← Formatters, validators
│   │   └── router.dart     ← go_router con guards por rol
│   ├── models/             ← User, Product, Order, Sale, Cart, Report
│   ├── services/           ← HTTP calls a la API
│   ├── providers/          ← Estado con Provider
│   ├── screens/
│   │   ├── auth/           ← Login, Register
│   │   ├── gerente/        ← Empleados, Reportes + shared
│   │   ├── cajero/         ← Ventas + shared
│   │   ├── almacenista/    ← shared
│   │   ├── cliente/        ← Catálogo, Carrito, Pedidos, Perfil
│   │   └── shared/         ← Inventario, Pedidos empleados, Buscar
│   └── widgets/            ← Componentes reutilizables
└── backend/                ← FastAPI
    ├── main.py
    ├── database.py
    ├── models.py           ← SQLAlchemy ORM
    ├── schemas.py          ← Pydantic
    ├── auth_utils.py       ← JWT + guards
    ├── routers/
    │   ├── auth.py
    │   ├── products.py
    │   ├── employees.py
    │   ├── orders.py
    │   ├── sales.py
    │   ├── cart.py
    │   └── reports.py
    ├── parfum_db.sql       ← Script MySQL
    └── requirements.txt
```

---

## Instalación

### 1. Base de datos MySQL

```bash
# Crear la base de datos e insertar datos iniciales
mysql -u root -p < backend/parfum_db.sql
```

### 2. Backend FastAPI

```bash
cd backend
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Editar database.py y cambiar la URL de conexión:
# DATABASE_URL = "mysql+pymysql://TU_USER:TU_PASSWORD@localhost:3306/parfum_db"

uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Documentación interactiva: http://localhost:8000/docs

### 3. Flutter App

```bash
cd parfum   # raíz del proyecto Flutter
flutter pub get
flutter run
```

> **Nota de conexión:** En `lib/core/network/api_client.dart` ajusta `_baseUrl`:
> - Emulador Android → `http://10.0.2.2:8000`
> - Simulador iOS / Web → `http://localhost:8000`
> - Dispositivo físico → `http://192.168.X.X:8000` (IP de tu máquina)

---

## Credenciales de prueba

| Rol          | Email                | Password    |
|-------------|----------------------|-------------|
| Gerente      | gerente@parfum.mx   | Admin123    |
| Cajero       | cajero@parfum.mx    | Cajero123   |
| Almacenista  | almacen@parfum.mx   | Almacen123  |
| Cliente      | (registrarse)        | —           |

> ⚠️ Los hashes en el SQL son de ejemplo. Para producción genera los tuyos con:
> ```python
> from passlib.context import CryptContext
> pwd = CryptContext(schemes=["bcrypt"])
> print(pwd.hash("TuPassword"))
> ```

---

## Flujo por rol

### Gerente
- Gestionar empleados (alta, edición, baja)
- Inventario completo (CRUD + imágenes)
- Ver y actualizar status de todos los pedidos
- Realizar ventas en caja
- Buscar productos
- Reportes con gráficas por período y categoría

### Cajero
- Realizar ventas en caja (buscar por SKU, ticket, cambio)
- Ver y actualizar pedidos
- Buscar productos
- Ver sus propios reportes de ventas

### Almacenista
- Gestionar inventario (stock, estado)
- Ver y actualizar status de pedidos
- Buscar productos

### Cliente
- Registro propio
- Catálogo con búsqueda y filtros
- Carrito de compras (persistido en API)
- Realizar pedidos con transferencia bancaria
- Ver historial y cancelar pedidos pendientes
- Editar su perfil

---

## Variables a cambiar antes de producción

| Archivo                        | Variable          | Descripción                        |
|-------------------------------|-------------------|------------------------------------|
| `backend/database.py`         | `DATABASE_URL`    | Credenciales MySQL                 |
| `backend/auth_utils.py`       | `SECRET_KEY`      | Clave secreta JWT (mín. 32 chars)  |
| `lib/core/network/api_client.dart` | `_baseUrl`   | URL del servidor FastAPI           |
| `backend/main.py`             | `allow_origins`   | Restringir CORS en producción      |
