from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from database import get_db
import models

# ── Configuración ─────────────────────────────────────────────────
SECRET_KEY  = "CAMBIA_ESTA_CLAVE_POR_UNA_SEGURA_EN_PRODUCCION"
ALGORITHM   = "HS256"
TOKEN_EXPIRE_HOURS = 24

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

# ── Hashing ───────────────────────────────────────────────────────
def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

# ── JWT ───────────────────────────────────────────────────────────
def create_token(user_id: int, rol: str) -> str:
    expire = datetime.utcnow() + timedelta(hours=TOKEN_EXPIRE_HOURS)
    return jwt.encode(
        {"sub": str(user_id), "rol": rol, "exp": expire},
        SECRET_KEY, algorithm=ALGORITHM,
    )

def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
        )

# ── Dependency: usuario actual ────────────────────────────────────
def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> models.User:
    payload = decode_token(token)
    user_id = int(payload.get("sub", 0))
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user or user.estado == "inactivo":
        raise HTTPException(status_code=401, detail="Usuario no autorizado")
    return user

# ── Guards por rol ────────────────────────────────────────────────
def require_roles(*roles: str):
    def checker(current_user: models.User = Depends(get_current_user)):
        if current_user.rol not in roles:
            raise HTTPException(status_code=403, detail="Sin permisos para esta acción")
        return current_user
    return checker

def only_gerente(user=Depends(require_roles("gerente"))): return user
def gerente_or_cajero(user=Depends(require_roles("gerente","cajero"))): return user
def empleados(user=Depends(require_roles("gerente","cajero","almacenista"))): return user
def any_user(user=Depends(get_current_user)): return user
