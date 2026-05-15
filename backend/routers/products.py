from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy.orm import Session
from typing import Optional, List
from database import get_db
from auth_utils import empleados, only_gerente, any_user
import models, schemas
import shutil, os, uuid

router = APIRouter()

UPLOAD_DIR = "uploads/products"
os.makedirs(UPLOAD_DIR, exist_ok=True)

def _update_estado(product: models.Product):
    """Actualiza el estado del producto según stock."""
    if product.estado == "inactivo":
        return
    if product.stock == 0:
        product.estado = "sin_stock"
    elif product.stock <= 5:
        product.estado = "bajo_stock"
    else:
        product.estado = "disponible"

@router.get("", response_model=List[schemas.ProductOut])
def get_products(
    search: Optional[str] = Query(None),
    categoria: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    _=Depends(any_user),
):
    q = db.query(models.Product).filter(models.Product.estado != "inactivo")
    if search:
        q = q.filter(
            models.Product.nombre.ilike(f"%{search}%") |
            models.Product.sku.ilike(f"%{search}%")
        )
    if categoria:
        q = q.filter(models.Product.categoria == categoria)
    return q.order_by(models.Product.nombre).all()

@router.get("/sku/{sku}", response_model=schemas.ProductOut)
def get_by_sku(sku: str, db: Session = Depends(get_db), _=Depends(any_user)):
    p = db.query(models.Product).filter(models.Product.sku == sku.upper()).first()
    if not p:
        raise HTTPException(status_code=404, detail=f"Producto con SKU '{sku}' no encontrado")
    return p

@router.get("/{product_id}", response_model=schemas.ProductOut)
def get_product(product_id: int, db: Session = Depends(get_db), _=Depends(any_user)):
    p = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return p

@router.post("", response_model=schemas.ProductOut)
def create_product(
    data: schemas.ProductCreate,
    db: Session = Depends(get_db),
    _=Depends(empleados),
):
    if db.query(models.Product).filter(models.Product.sku == data.sku.upper()).first():
        raise HTTPException(status_code=400, detail="SKU ya registrado")
    p = models.Product(**data.model_dump(), sku=data.sku.upper())
    _update_estado(p)
    db.add(p); db.commit(); db.refresh(p)
    return p

@router.put("/{product_id}", response_model=schemas.ProductOut)
def update_product(
    product_id: int,
    data: schemas.ProductUpdate,
    db: Session = Depends(get_db),
    _=Depends(empleados),
):
    p = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    for field, val in data.model_dump(exclude_unset=True).items():
        setattr(p, field, val)
    _update_estado(p)
    db.commit(); db.refresh(p)
    return p

@router.delete("/{product_id}")
def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    _=Depends(empleados),
):
    p = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    p.estado = "inactivo"
    db.commit()
    return {"message": "Producto dado de baja correctamente"}

@router.post("/{product_id}/image")
def upload_image(
    product_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    _=Depends(empleados),
):
    p = db.query(models.Product).filter(models.Product.id == product_id).first()
    if not p:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    ext = file.filename.split(".")[-1]
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)
    with open(filepath, "wb") as buf:
        shutil.copyfileobj(file.file, buf)
    p.imagen_url = f"/uploads/products/{filename}"
    db.commit()
    return {"imagen_url": p.imagen_url}
