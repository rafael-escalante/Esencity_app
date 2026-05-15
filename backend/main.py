from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from database import engine, Base
from routers import auth, products, employees, orders, sales, cart, reports

# Crear tablas si no existen
Base.metadata.create_all(bind=engine)

app = FastAPI(title="PARFUM API", version="1.0.0")

# CORS — permite Flutter en desarrollo (ajusta origins en producción)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth.router,      prefix="/auth",     tags=["Auth"])
app.include_router(products.router,  prefix="/products", tags=["Products"])
app.include_router(employees.router, prefix="/employees",tags=["Employees"])
app.include_router(orders.router,    prefix="/orders",   tags=["Orders"])
app.include_router(sales.router,     prefix="/sales",    tags=["Sales"])
app.include_router(cart.router,      prefix="/cart",     tags=["Cart"])
app.include_router(reports.router,   prefix="/reports",  tags=["Reports"])

@app.get("/")
def root():
    return {"message": "PARFUM API v1.0"}
