from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from auth_utils import gerente_or_cajero
import models, schemas

router = APIRouter()

IVA_RATE = 0.16

def _build_sale_out(sale: models.Sale) -> schemas.SaleOut:
    return schemas.SaleOut(
        id=sale.id,
        cajero_nombre=sale.cajero.nombre if sale.cajero else "—",
        fecha=sale.fecha,
        subtotal=sale.subtotal,
        iva=sale.iva,
        total=sale.total,
        metodo_pago=sale.metodo_pago,
        monto_recibido=sale.monto_recibido,
        cambio=sale.cambio,
    )


@router.get("", response_model=List[schemas.SaleOut])
def get_sales(
    db: Session = Depends(get_db),
    current_user=Depends(gerente_or_cajero),
):
    q = db.query(models.Sale)
    # Cajero solo ve sus propias ventas
    if current_user.rol == "cajero":
        q = q.filter(models.Sale.cajero_id == current_user.id)
    sales = q.order_by(models.Sale.fecha.desc()).all()
    return [_build_sale_out(s) for s in sales]


@router.get("/{sale_id}", response_model=schemas.SaleOut)
def get_sale(
    sale_id: int,
    db: Session = Depends(get_db),
    _=Depends(gerente_or_cajero),
):
    sale = db.query(models.Sale).filter(models.Sale.id == sale_id).first()
    if not sale:
        raise HTTPException(status_code=404, detail="Venta no encontrada")
    return _build_sale_out(sale)


@router.post("", response_model=schemas.SaleOut)
def create_sale(
    data: schemas.SaleCreate,
    db: Session = Depends(get_db),
    current_user=Depends(gerente_or_cajero),
):
    if not data.items:
        raise HTTPException(status_code=400, detail="La venta debe tener al menos un producto")

    subtotal = 0.0
    sale_items = []

    for item_in in data.items:
        product = db.query(models.Product).filter(
            models.Product.id == item_in.producto_id
        ).first()
        if not product:
            raise HTTPException(
                status_code=404,
                detail=f"Producto ID {item_in.producto_id} no encontrado",
            )
        if product.stock < item_in.cantidad:
            raise HTTPException(
                status_code=400,
                detail=f"Stock insuficiente para '{product.nombre}' (disponible: {product.stock})",
            )
        line_total = product.precio * item_in.cantidad
        subtotal += line_total
        sale_items.append((product, item_in.cantidad, product.precio))

    iva    = round(subtotal * IVA_RATE, 2)
    total  = round(subtotal + iva, 2)
    cambio = round(data.monto_recibido - total, 2) if data.metodo_pago == "Efectivo" else 0.0

    if data.metodo_pago == "Efectivo" and data.monto_recibido < total:
        raise HTTPException(status_code=400, detail="Monto recibido insuficiente")

    sale = models.Sale(
        cajero_id=current_user.id,
        subtotal=round(subtotal, 2),
        iva=iva,
        total=total,
        metodo_pago=data.metodo_pago,
        monto_recibido=data.monto_recibido,
        cambio=cambio,
    )
    db.add(sale)
    db.flush()

    for product, cantidad, precio in sale_items:
        db.add(models.SaleItem(
            sale_id=sale.id,
            producto_id=product.id,
            cantidad=cantidad,
            precio_unitario=precio,
        ))
        product.stock -= cantidad
        from routers.products import _update_estado
        _update_estado(product)

    db.commit()
    db.refresh(sale)
    return _build_sale_out(sale)


@router.delete("/{sale_id}")
def cancel_sale(
    sale_id: int,
    db: Session = Depends(get_db),
    _=Depends(gerente_or_cajero),
):
    sale = db.query(models.Sale).filter(models.Sale.id == sale_id).first()
    if not sale:
        raise HTTPException(status_code=404, detail="Venta no encontrada")

    # Restaurar stock
    for item in sale.items:
        if item.product:
            item.product.stock += item.cantidad
            from routers.products import _update_estado
            _update_estado(item.product)

    db.delete(sale)
    db.commit()
    return {"message": "Venta cancelada y stock restaurado"}
