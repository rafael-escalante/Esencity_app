from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from auth_utils import get_current_user
import models, schemas

router = APIRouter()

def _build_cart_out(ci: models.CartItem) -> schemas.CartItemOut:
    return schemas.CartItemOut(
        id=ci.id,
        producto_id=ci.producto_id,
        nombre=ci.product.nombre if ci.product else "—",
        descripcion=f"{ci.product.concentracion} {ci.product.ml}ml" if ci.product else "",
        precio=ci.product.precio if ci.product else 0.0,
        cantidad=ci.cantidad,
    )


@router.get("", response_model=List[schemas.CartItemOut])
def get_cart(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    items = (
        db.query(models.CartItem)
        .filter(models.CartItem.user_id == current_user.id)
        .all()
    )
    return [_build_cart_out(i) for i in items]


@router.post("", response_model=schemas.CartItemOut)
def add_to_cart(
    data: schemas.CartItemIn,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    product = db.query(models.Product).filter(models.Product.id == data.producto_id).first()
    if not product:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    if product.stock < data.cantidad:
        raise HTTPException(status_code=400, detail="Stock insuficiente")

    existing = (
        db.query(models.CartItem)
        .filter(
            models.CartItem.user_id == current_user.id,
            models.CartItem.producto_id == data.producto_id,
        )
        .first()
    )
    if existing:
        existing.cantidad += data.cantidad
        db.commit()
        db.refresh(existing)
        return _build_cart_out(existing)

    item = models.CartItem(
        user_id=current_user.id,
        producto_id=data.producto_id,
        cantidad=data.cantidad,
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return _build_cart_out(item)


@router.put("/{item_id}", response_model=schemas.CartItemOut)
def update_cart_item(
    item_id: int,
    data: schemas.CartItemUpdate,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    item = (
        db.query(models.CartItem)
        .filter(
            models.CartItem.id == item_id,
            models.CartItem.user_id == current_user.id,
        )
        .first()
    )
    if not item:
        raise HTTPException(status_code=404, detail="Item no encontrado en el carrito")
    if data.cantidad <= 0:
        db.delete(item)
        db.commit()
        raise HTTPException(status_code=204, detail="Item eliminado")
    item.cantidad = data.cantidad
    db.commit()
    db.refresh(item)
    return _build_cart_out(item)


@router.delete("/{item_id}")
def remove_cart_item(
    item_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    item = (
        db.query(models.CartItem)
        .filter(
            models.CartItem.id == item_id,
            models.CartItem.user_id == current_user.id,
        )
        .first()
    )
    if not item:
        raise HTTPException(status_code=404, detail="Item no encontrado")
    db.delete(item)
    db.commit()
    return {"message": "Item eliminado del carrito"}


@router.delete("")
def clear_cart(
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    db.query(models.CartItem).filter(
        models.CartItem.user_id == current_user.id
    ).delete()
    db.commit()
    return {"message": "Carrito vaciado"}
