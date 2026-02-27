from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import users

app = FastAPI(title="Auth Service")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router, prefix="/api/users", tags=["users"])

@app.get("/health")
async def health():
    return {"status": "ok", "service": "auth-service"}