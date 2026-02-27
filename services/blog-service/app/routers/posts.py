from datetime import datetime
from fastapi import APIRouter, Depends, Header
from pydantic import BaseModel
from typing import Optional
from app.auth import get_user_token, require_service_token

router          = APIRouter()
internal_router = APIRouter()

# In-memory store — replace with a real DB in production
_posts: list[dict] = []


class PostCreate(BaseModel):
    title:     str
    content:   str
    published: bool = True


@router.get("")
async def list_posts(_: dict = Depends(get_user_token)):
    return [p for p in _posts if p["published"]]


@router.post("", status_code=201)
async def create_post(body: PostCreate, user: dict = Depends(get_user_token)):
    post = {
        "id":          str(len(_posts) + 1),
        "title":       body.title,
        "content":     body.content,
        "author_id":   user["sub"],
        "author_name": user.get("preferred_username", "Anonymous"),
        "created_at":  datetime.utcnow().isoformat(),
        "published":   body.published,
    }
    _posts.append(post)
    return post


@internal_router.get("")
async def get_user_posts(
    _:          dict = Depends(require_service_token),
    x_user_id: str  = Header(..., alias="X-User-Id"),
):
    return [p for p in _posts if p["author_id"] == x_user_id]