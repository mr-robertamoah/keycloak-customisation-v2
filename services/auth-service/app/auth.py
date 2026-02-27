import os
import httpx
from functools import lru_cache
from typing import Optional
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from pydantic import BaseModel

KEYCLOAK_URL   = os.getenv("KEYCLOAK_URL",   "http://keycloak:8080")
KEYCLOAK_PUBLIC_URL = os.getenv("KEYCLOAK_PUBLIC_URL", "http://localhost:8080")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "write-place")

bearer = HTTPBearer()


class TokenData(BaseModel):
    sub: str
    email: Optional[str] = None
    given_name: Optional[str] = None
    family_name: Optional[str] = None
    preferred_username: Optional[str] = None
    realm_roles: list[str] = []


@lru_cache(maxsize=1)
def _jwks_uri() -> str:
    r = httpx.get(
        f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}/.well-known/openid-configuration"
    )
    r.raise_for_status()
    return r.json()["jwks_uri"]


def _public_keys():
    return httpx.get(_jwks_uri()).json()["keys"]

def _allowed_issuers() -> list[str]:
    issuers = {
        f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}",
        f"{KEYCLOAK_PUBLIC_URL}/realms/{KEYCLOAK_REALM}",
    }
    return list(issuers)


def verify_token(token: str) -> TokenData:
    payload = None
    last_error = None
    try:
        for issuer in _allowed_issuers():
            try:
                payload = jwt.decode(
                    token,
                    _public_keys(),
                    algorithms=["RS256"],
                    options={"verify_aud": False},
                    issuer=issuer,
                )
                break
            except JWTError as e:
                last_error = e
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Invalid token") from e

    if payload is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED,
                            detail="Invalid token") from last_error

    roles = payload.get("realm_access", {}).get("roles", [])
    return TokenData(
        sub=payload["sub"],
        email=payload.get("email"),
        given_name=payload.get("given_name"),
        family_name=payload.get("family_name"),
        preferred_username=payload.get("preferred_username"),
        realm_roles=roles,
    )


async def get_current_user(
    creds: HTTPAuthorizationCredentials = Depends(bearer),
) -> TokenData:
    return verify_token(creds.credentials)
