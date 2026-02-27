from fastapi import FastAPI
from app.routers import posts

app = FastAPI(title="Blog Service")
app.include_router(posts.router,          prefix="/api/posts",    tags=["posts"])
app.include_router(posts.internal_router, prefix="/internal/posts", tags=["internal"])

@app.get("/health")
async def health():
    return {"status": "ok", "service": "blog-service"}