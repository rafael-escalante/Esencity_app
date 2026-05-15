from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import enum

class RolEnum(str, enum.Enum):
    gerente     = "gerente"
    cajero      = "cajero"
    almacenista = "almacenista"
    cliente     = "cliente"

class EstadoProductoEnum(str, enum.Enum):
    disponible = "disponible"
    bajo_stock = "bajo_stock"
    sin_stock  = "sin_stock"
    inactivo   = "inactivo"

class StatusPedidoEnum(str, enum.Enum):
    pendiente   = "Pendiente"
    pagado      = "Pagado"
    listo       = "Listo para entrega"
    finalizado  = "Finalizado"
    cancelado   = "Cancelado"

class User(Base):
    __tablename__ = "users"
    id             = Column(Integer, primary_key=True, index=True)
    nombre         = Column(String(100), nullable=False)
    email          = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password= Column(String(255), nullable=False)
    rol            = Column(Enum(RolEnum), default=RolEnum.cliente)
    rfc            = Column(String(20), nullable=True)
    telefono       = Column(String(20), nullable=True)
    estado         = Column(String(20), default="activo")
    fecha_registro = Column(DateTime(timezone=True), server_default=func.now())

    orders     = relationship("Order",   back_populates="cliente")
    cart_items = relationship("CartItem",back_populates="user")

class Product(Base):
    __tablename__ = "products"
    id             = Column(Integer, primary_key=True, index=True)
    sku            = Column(String(30), unique=True, index=True, nullable=False)
    nombre         = Column(String(150), nullable=False)
    descripcion    = Column(Text, nullable=True)
    categoria      = Column(String(50), nullable=False)
    concentracion  = Column(String(10), nullable=False)
    ml             = Column(Integer, nullable=False)
    precio         = Column(Float, nullable=False)
    stock          = Column(Integer, default=0)
    estado         = Column(Enum(EstadoProductoEnum), default=EstadoProductoEnum.disponible)
    imagen_url     = Column(String(500), nullable=True)
    fecha_registro = Column(DateTime(timezone=True), server_default=func.now())

class Order(Base):
    __tablename__ = "orders"
    id             = Column(Integer, primary_key=True, index=True)
    user_id        = Column(Integer, ForeignKey("users.id"))
    fecha          = Column(DateTime(timezone=True), server_default=func.now())
    total          = Column(Float, nullable=False)
    status         = Column(String(50), default="Pendiente")
    metodo_pago    = Column(String(50), nullable=True)
    referencia     = Column(String(100), nullable=True)
    banco          = Column(String(100), nullable=True)

    cliente = relationship("User",      back_populates="orders")
    items   = relationship("OrderItem", back_populates="order", cascade="all, delete-orphan")

class OrderItem(Base):
    __tablename__ = "order_items"
    id             = Column(Integer, primary_key=True, index=True)
    order_id       = Column(Integer, ForeignKey("orders.id"))
    producto_id    = Column(Integer, ForeignKey("products.id"))
    cantidad       = Column(Integer, nullable=False)
    precio_unitario= Column(Float, nullable=False)

    order   = relationship("Order",   back_populates="items")
    product = relationship("Product")

class Sale(Base):
    __tablename__ = "sales"
    id             = Column(Integer, primary_key=True, index=True)
    cajero_id      = Column(Integer, ForeignKey("users.id"))
    fecha          = Column(DateTime(timezone=True), server_default=func.now())
    subtotal       = Column(Float, nullable=False)
    iva            = Column(Float, nullable=False)
    total          = Column(Float, nullable=False)
    metodo_pago    = Column(String(50), nullable=False)
    monto_recibido = Column(Float, nullable=False)
    cambio         = Column(Float, default=0)

    cajero = relationship("User")
    items  = relationship("SaleItem", back_populates="sale", cascade="all, delete-orphan")

class SaleItem(Base):
    __tablename__ = "sale_items"
    id          = Column(Integer, primary_key=True, index=True)
    sale_id     = Column(Integer, ForeignKey("sales.id"))
    producto_id = Column(Integer, ForeignKey("products.id"))
    cantidad    = Column(Integer, nullable=False)
    precio_unitario = Column(Float, nullable=False)

    sale    = relationship("Sale",    back_populates="items")
    product = relationship("Product")

class CartItem(Base):
    __tablename__ = "cart_items"
    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id"))
    producto_id = Column(Integer, ForeignKey("products.id"))
    cantidad    = Column(Integer, default=1)

    user    = relationship("User",    back_populates="cart_items")
    product = relationship("Product")
