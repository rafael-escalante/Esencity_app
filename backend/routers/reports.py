from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional
from datetime import datetime
from database import get_db
from auth_utils import gerente_or_cajero
import models, schemas

router = APIRouter()

@router.get("/sales", response_model=schemas.ReportOut)
def generate_report(
    fecha_inicio: str = Query(...),
    fecha_fin:    str = Query(...),
    categoria:    Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user=Depends(gerente_or_cajero),
):
    date_from = datetime.strptime(fecha_inicio, "%Y-%m-%d")
    date_to   = datetime.strptime(fecha_fin,    "%Y-%m-%d").replace(hour=23, minute=59, second=59)

    # Cajero solo ve sus propias ventas
    q = db.query(models.Sale).filter(
        models.Sale.fecha >= date_from,
        models.Sale.fecha <= date_to,
    )
    if current_user.rol == "cajero":
        q = q.filter(models.Sale.cajero_id == current_user.id)

    sales = q.order_by(models.Sale.fecha).all()

    if not sales:
        return schemas.ReportOut(
            total_ventas=0, total_transacciones=0,
            producto_mas_vendido="Sin ventas", unidades_producto_top=0,
            categoria_lider="—", porcentaje_categoria=0,
            por_periodo=[], detalle=[],
        )

    sale_ids = [s.id for s in sales]

    # Filtrar items por categoría si aplica
    items_q = db.query(models.SaleItem).filter(models.SaleItem.sale_id.in_(sale_ids))
    if categoria:
        items_q = items_q.join(models.Product).filter(models.Product.categoria == categoria)
    all_items = items_q.all()

    # Totales generales
    total_ventas       = sum(s.total for s in sales)
    total_transacciones= len(sales)

    # Producto más vendido
    product_qty: dict[str, int] = {}
    category_total: dict[str, float] = {}

    for item in all_items:
        if item.product:
            name = item.product.nombre
            cat  = item.product.categoria
            product_qty[name]    = product_qty.get(name, 0) + item.cantidad
            category_total[cat]  = category_total.get(cat, 0.0) + (item.precio_unitario * item.cantidad)

    top_product  = max(product_qty, key=product_qty.get) if product_qty else "—"
    top_units    = product_qty.get(top_product, 0)
    top_category = max(category_total, key=category_total.get) if category_total else "—"
    top_cat_pct  = round(
        (category_total.get(top_category, 0) / total_ventas * 100) if total_ventas else 0, 1
    )

    # Agrupar por mes (periodo)
    period_map: dict[str, float] = {}
    for s in sales:
        key = s.fecha.strftime("%b %Y")
        period_map[key] = period_map.get(key, 0.0) + s.total

    por_periodo = [
        schemas.ReportPeriod(periodo=k, total=round(v, 2))
        for k, v in period_map.items()
    ]

    # Tabla detalle
    detalle = []
    for s in sales:
        cajero_name = s.cajero.nombre if s.cajero else "—"
        for item in s.items:
            if categoria and item.product and item.product.categoria != categoria:
                continue
            detalle.append(schemas.ReportDetail(
                fecha=s.fecha.strftime("%d/%b/%Y"),
                cajero=cajero_name,
                producto=item.product.nombre if item.product else "—",
                cantidad=item.cantidad,
                total=round(item.precio_unitario * item.cantidad, 2),
                metodo_pago=s.metodo_pago,
            ))

    return schemas.ReportOut(
        total_ventas=round(total_ventas, 2),
        total_transacciones=total_transacciones,
        producto_mas_vendido=top_product,
        unidades_producto_top=top_units,
        categoria_lider=top_category,
        porcentaje_categoria=top_cat_pct,
        por_periodo=por_periodo,
        detalle=detalle,
    )
