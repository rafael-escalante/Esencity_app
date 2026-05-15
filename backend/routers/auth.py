from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from auth_utils import hash_password, verify_password, create_token, get_current_user
import models, schemas

router = APIRouter()

@router.post("/login", response_model=schemas.TokenResponse)
def login(data: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == data.email).first()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Correo o contraseña incorrectos")
    if user.estado == "inactivo":
        raise HTTPException(status_code=403, detail="Usuario dado de baja")
    token = create_token(user.id, user.rol)
    return {"access_token": token, "user": user}

@router.post("/register", response_model=schemas.TokenResponse)
def register(data: schemas.RegisterRequest, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.email == data.email).first():
        raise HTTPException(status_code=400, detail="El correo ya está registrado")
    user = models.User(
        nombre=data.nombre, email=data.email,
        hashed_password=hash_password(data.password),
        telefono=data.telefono, rol="cliente",
    )
    db.add(user); db.commit(); db.refresh(user)
    token = create_token(user.id, user.rol)
    return {"access_token": token, "user": user}

@router.get("/me", response_model=schemas.UserOut)
def me(current_user=Depends(get_current_user)):
    return current_user

@router.post("/logout")
def logout():
    # El cliente elimina el token localmente
    return {"message": "Sesión cerrada"}

@router.put("/users/{user_id}", response_model=schemas.UserOut)
def update_profile(
    user_id: int,
    data: schemas.UpdateProfileRequest,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user),
):
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="No puedes editar otro usuario")
    if data.nombre:   current_user.nombre   = data.nombre
    if data.telefono: current_user.telefono = data.telefono
    db.commit(); db.refresh(current_user)
    return current_user
