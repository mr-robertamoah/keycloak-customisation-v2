import os
import httpx
from fastapi import APIRouter, Depends
from app.auth import get_current_user, TokenData

router = APIRouter()

BLOG_SERVICE_URL      = os.getenv("BLOG_SERVICE_URL", "http://blog-service:8002")
KEYCLOAK_URL          = os.getenv("KEYCLOAK_URL",     "http://keycloak:8080")
KEYCLOAK_REALM        = os.getenv("KEYCLOAK_REALM",   "write-place")
KEYCLOAK_CLIENT_ID    = os.getenv("KEYCLOAK_CLIENT_ID")
KEYCLOAK_CLIENT_SECRET = os.getenv("KEYCLOAK_CLIENT_SECRET")


@router.get("/me")
async def get_me(user: TokenData = Depends(get_current_user)):
    return {
        "id": user.sub,
        "email": user.email,
        "username": user.preferred_username,
        "firstName": user.given_name,
        "lastName": user.family_name,
        "roles": user.realm_roles,
    }


async def _service_token() -> str:
    """Obtain a machine-to-machine token using Client Credentials grant."""
    async with httpx.AsyncClient() as client:
        r = await client.post(
            f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}/protocol/openid-connect/token",
            data={
                "grant_type": "client_credentials",
                "client_id": KEYCLOAK_CLIENT_ID,
                "client_secret": KEYCLOAK_CLIENT_SECRET,
            },
        )
        r.raise_for_status()
        return r.json()["access_token"]


@router.get("/me/posts")
async def get_my_posts(user: TokenData = Depends(get_current_user)):
    """
    Fetch this user's posts from the Blog Service.
    We authenticate to Blog Service with a service account token,
    and pass the original user's ID in a header.
    """
    svc_token = await _service_token()
    async with httpx.AsyncClient() as client:
        r = await client.get(
            f"{BLOG_SERVICE_URL}/internal/posts",
            headers={
                "Authorization": f"Bearer {svc_token}",
                "X-User-Id": user.sub,
            },
        )
        r.raise_for_status()
        return r.json()