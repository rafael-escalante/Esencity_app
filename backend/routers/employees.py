from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional, List
from database import get_db
from auth_utils import only_gerente, hash_password
import models, schemas

router = APIRouter()

@router.get("", response_model=List[schemas.EmployeeOut])
def get_employees(
    search: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    _=Depends(only_gerente),
):
    q = db.query(models.User).filter(
        models.User.rol.in_(["cajero", "almacenista"])
    )
    if search:
        q = q.filter(
            models.User.nombre.ilike(f"%{search}%") |
            models.User.email.ilike(f"%{search}%") |
            models.User.rfc.ilike(f"%{search}%")
        )
    users = q.order_by(models.User.nombre).all()
    return [_to_employee_out(u) for u in users]

@router.get("/{emp_id}", response_model=schemas.EmployeeOut)
def get_employee(emp_id: int, db: Session = Depends(get_db), _=Depends(only_gerente)):
    u = db.query(models.User).filter(models.User.id == emp_id).first()
    if not u:
        raise HTTPException(status_code=404, detail="Empleado no encontrado")
    return _to_employee_out(u)

@router.post("", response_model=schemas.EmployeeOut)
def create_employee(
    data: schemas.EmployeeCreate,
    db: Session = Depends(get_db),
    _=Depends(only_gerente),
):
    if db.query(models.User).filter(models.User.email == data.email).first():
        raise HTTPException(status_code=400, detail="El correo ya está registrado")
    if db.query(models.User).filter(models.User.rfc == data.rfc.upper()).first():
        raise HTTPException(status_code=400, detail="El RFC ya está registrado")
    u = models.User(
        nombre=data.nombre, email=data.email, rfc=data.rfc.upper(),
        rol=data.puesto, hashed_password=hash_password(data.password),
        estado="activo",
    )
    db.add(u); db.commit(); db.refresh(u)
    return _to_employee_out(u)

@router.put("/{emp_id}", response_model=schemas.EmployeeOut)
def update_employee(
    emp_id: int,
    data: schemas.EmployeeUpdate,
    db: Session = Depends(get_db),
    _=Depends(only_gerente),
):
    u = db.query(models.User).filter(models.User.id == emp_id).first()
    if not u:
        raise HTTPException(status_code=404, detail="Empleado no encontrado")
    if data.nombre:  u.nombre = data.nombre
    if data.email:   u.email  = data.email
    if data.puesto:  u.rol    = data.puesto
    db.commit(); db.refresh(u)
    return _to_employee_out(u)

@router.patch("/{emp_id}/disable")
def disable_employee(
    emp_id: int,
    db: Session = Depends(get_db),
    _=Depends(only_gerente),
):
    u = db.query(models.User).filter(models.User.id == emp_id).first()
    if not u:
        raise HTTPException(status_code=404, detail="Empleado no encontrado")
    u.estado = "inactivo"
    db.commit()
    return {"message": f"Empleado {u.nombre} dado de baja"}

def _to_employee_out(u: models.User) -> schemas.EmployeeOut:
    return schemas.EmployeeOut(
        id=u.id, nombre=u.nombre, rfc=u.rfc or "",
        email=u.email, puesto=u.rol, estado=u.estado,
        fecha_registro=u.fecha_registro,
    )
