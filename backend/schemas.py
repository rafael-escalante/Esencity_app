from pydantic import BaseModel, EmailStr
from typing import Optional, List
from datetime import datetime

# ── Auth ──────────────────────────────────────────────────────────
class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class RegisterRequest(BaseModel):
    nombre: str
    email: EmailStr
    password: str
    telefono: Optional[str] = None

class UserOut(BaseModel):
    id: int
    nombre: str
    email: str
    rol: str
    telefono: Optional[str] = None
    class Config: from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut

class UpdateProfileRequest(BaseModel):
    nombre: Optional[str] = None
    telefono: Optional[str] = None

# ── Products ──────────────────────────────────────────────────────
class ProductCreate(BaseModel):
    sku: str
    nombre: str
    descripcion: Optional[str] = ""
    categoria: str
    concentracion: str
    ml: int
    precio: float
    stock: int

class ProductUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    categoria: Optional[str] = None
    concentracion: Optional[str] = None
    ml: Optional[int] = None
    precio: Optional[float] = None
    stock: Optional[int] = None
    estado: Optional[str] = None

class ProductOut(BaseModel):
    id: int
    sku: str
    nombre: str
    descripcion: Optional[str] = ""
    categoria: str
    concentracion: str
    ml: int
    precio: float
    stock: int
    estado: str
    imagen_url: Optional[str] = None
    fecha_registro: Optional[datetime] = None
    class Config: from_attributes = True

# ── Employees ─────────────────────────────────────────────────────
class EmployeeCreate(BaseModel):
    nombre: str
    rfc: str
    email: EmailStr
    puesto: str  # cajero | almacenista
    password: str

class EmployeeUpdate(BaseModel):
    nombre: Optional[str] = None
    email: Optional[EmailStr] = None
    puesto: Optional[str] = None

class EmployeeOut(BaseModel):
    id: int
    nombre: str
    rfc: str
    email: str
    puesto: str
    estado: str
    fecha_registro: Optional[datetime] = None
    class Config: from_attributes = True

# ── Orders ────────────────────────────────────────────────────────
class OrderItemOut(BaseModel):
    id: int
    producto_id: int
    nombre_producto: str
    cantidad: int
    precio_unitario: float
    class Config: from_attributes = True

class OrderCreate(BaseModel):
    metodo_pago: str
    referencia: str
    banco: str

class OrderStatusUpdate(BaseModel):
    status: str

class OrderCancelRequest(BaseModel):
    motivo: Optional[str] = None

class OrderOut(BaseModel):
    id: int
    cliente_nombre: str
    fecha: datetime
    total: float
    status: str
    metodo_pago: Optional[str] = None
    referencia: Optional[str] = None
    items: List[OrderItemOut] = []
    class Config: from_attributes = True

# ── Sales ─────────────────────────────────────────────────────────
class SaleItemIn(BaseModel):
    producto_id: int
    cantidad: int

class SaleCreate(BaseModel):
    items: List[SaleItemIn]
    metodo_pago: str
    monto_recibido: float

class SaleOut(BaseModel):
    id: int
    cajero_nombre: str
    fecha: datetime
    subtotal: float
    iva: float
    total: float
    metodo_pago: str
    monto_recibido: float
    cambio: float
    class Config: from_attributes = True

# ── Cart ──────────────────────────────────────────────────────────
class CartItemIn(BaseModel):
    producto_id: int
    cantidad: int

class CartItemUpdate(BaseModel):
    cantidad: int

class CartItemOut(BaseModel):
    id: int
    producto_id: int
    nombre: str
    descripcion: Optional[str] = ""
    precio: float
    cantidad: int
    class Config: from_attributes = True

# ── Reports ───────────────────────────────────────────────────────
class ReportPeriod(BaseModel):
    periodo: str
    total: float

class ReportDetail(BaseModel):
    fecha: str
    cajero: str
    producto: str
    cantidad: int
    total: float
    metodo_pago: str

class ReportOut(BaseModel):
    total_ventas: float
    total_transacciones: int
    producto_mas_vendido: str
    unidades_producto_top: int
    categoria_lider: str
    porcentaje_categoria: float
    por_periodo: List[ReportPeriod]
    detalle: List[ReportDetail]
