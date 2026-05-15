from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from database import get_db
from auth_utils import get_current_user, empleados
import models, schemas

router = APIRouter()

def _build_order_out(order: models.Order) -> schemas.OrderOut:
    return schemas.OrderOut(
        id=order.id,
        cliente_nombre=order.cliente.nombre if order.cliente else "—",
        fecha=order.fecha,
        total=order.total,
        status=order.status,
        metodo_pago=order.metodo_pago,
        referencia=order.referencia,
        items=[
            schemas.OrderItemOut(
                id=i.id,
                producto_id=i.producto_id,
                nombre_producto=i.product.nombre if i.product else "—",
                cantidad=i.cantidad,
                precio_unitario=i.precio_unitario,
            )
            for i in order.items
        ],
    )


# ── Empleados: ver todos los pedidos ─────────────────────────────
@router.get("", response_model=List[schemas.OrderOut])
def get_all_orders(
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    _=Depends(empleados),
):
    q = db.query(models.Order)
    if status:
        q = q.filter(models.Order.status == status)
    orders = q.order_by(models.Order.fecha.desc()).all()
    return [_build_order_out(o) for o in orders]


# ── Cliente: solo sus pedidos ─────────────────────────────────────
@router.get("/my", response_model=List[schemas.OrderOut])
def get_my_orders(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    orders = (
        db.query(models.Order)
        .filter(models.Order.user_id == current_user.id)
        .order_by(models.Order.fecha.desc())
        .all()
    )
    return [_build_order_out(o) for o in orders]


@router.get("/{order_id}", response_model=schemas.OrderOut)
def get_order(
    order_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    # Cliente solo puede ver sus propios pedidos
    if current_user.rol == "cliente" and order.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Sin acceso a este pedido")
    return _build_order_out(order)


# ── Cliente: crear pedido desde su carrito ────────────────────────
@router.post("", response_model=schemas.OrderOut)
def create_order(
    data: schemas.OrderCreate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.rol != "cliente":
        raise HTTPException(status_code=403, detail="Solo clientes pueden crear pedidos")

    cart_items = (
        db.query(models.CartItem)
        .filter(models.CartItem.user_id == current_user.id)
        .all()
    )
    if not cart_items:
        raise HTTPException(status_code=400, detail="El carrito está vacío")

    # Calcular total
    total = 0.0
    for ci in cart_items:
        if not ci.product or ci.product.stock < ci.cantidad:
            raise HTTPException(
                status_code=400,
                detail=f"Stock insuficiente para '{ci.product.nombre if ci.product else ci.producto_id}'",
            )
        total += ci.product.precio * ci.cantidad

    order = models.Order(
        user_id=current_user.id,
        total=total,
        status="Pendiente",
        metodo_pago=data.metodo_pago,
        referencia=data.referencia,
        banco=data.banco,
    )
    db.add(order)
    db.flush()  # para obtener order.id antes del commit

    for ci in cart_items:
        item = models.OrderItem(
            order_id=order.id,
            producto_id=ci.producto_id,
            cantidad=ci.cantidad,
            precio_unitario=ci.product.precio,
        )
        db.add(item)
        # Descontar stock
        ci.product.stock -= ci.cantidad
        from routers.products import _update_estado
        _update_estado(ci.product)

    # Vaciar carrito
    db.query(models.CartItem).filter(models.CartItem.user_id == current_user.id).delete()
    db.commit()
    db.refresh(order)
    return _build_order_out(order)


# ── Empleados: actualizar status ──────────────────────────────────
@router.patch("/{order_id}/status", response_model=schemas.OrderOut)
def update_status(
    order_id: int,
    data: schemas.OrderStatusUpdate,
    db: Session = Depends(get_db),
    _=Depends(empleados),
):
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    if order.status == "Cancelado":
        raise HTTPException(status_code=400, detail="No se puede modificar un pedido cancelado")
    order.status = data.status
    db.commit()
    db.refresh(order)
    return _build_order_out(order)


# ── Cancelar pedido (cliente o empleado) ──────────────────────────
@router.patch("/{order_id}/cancel", response_model=schemas.OrderOut)
def cancel_order(
    order_id: int,
    data: schemas.OrderCancelRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    order = db.query(models.Order).filter(models.Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    if current_user.rol == "cliente" and order.user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Sin acceso")
    if order.status != "Pendiente":
        raise HTTPException(status_code=400, detail="Solo se pueden cancelar pedidos en estado Pendiente")

    # Restaurar stock
    for item in order.items:
        if item.product:
            item.product.stock += item.cantidad
            from routers.products import _update_estado
            _update_estado(item.product)

    order.status = "Cancelado"
    db.commit()
    db.refresh(order)
    return _build_order_out(order)
