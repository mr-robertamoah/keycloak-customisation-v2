import os
import httpx
from functools import lru_cache
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt

KEYCLOAK_URL   = os.getenv("KEYCLOAK_URL",   "http://keycloak:8080")
KEYCLOAK_PUBLIC_URL = os.getenv("KEYCLOAK_PUBLIC_URL", "http://localhost:8080")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "write-place")
TRUSTED_CLIENTS = {"auth-service"}

bearer = HTTPBearer(auto_error=False)


@lru_cache(maxsize=1)
def _jwks_uri():
    r = httpx.get(
        f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}/.well-known/openid-configuration"
    )
    r.raise_for_status()
    return r.json()["jwks_uri"]


def _decode(token: str) -> dict:
    payload = None
    last_error = None
    try:
        keys = httpx.get(_jwks_uri()).json()["keys"]
        for issuer in {
            f"{KEYCLOAK_URL}/realms/{KEYCLOAK_REALM}",
            f"{KEYCLOAK_PUBLIC_URL}/realms/{KEYCLOAK_REALM}",
        }:
            try:
                payload = jwt.decode(
                    token, keys, algorithms=["RS256"],
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

    return payload


async def get_user_token(
    creds: HTTPAuthorizationCredentials = Depends(bearer),
) -> dict:
    if not creds:
        raise HTTPException(status_code=401, detail="Not authenticated")
    return _decode(creds.credentials)


async def require_service_token(
    creds: HTTPAuthorizationCredentials = Depends(bearer),
) -> dict:
    if not creds:
        raise HTTPException(status_code=401, detail="Not authenticated")
    payload = _decode(creds.credentials)
    if payload.get("azp", "") not in TRUSTED_CLIENTS:
        raise HTTPException(status_code=403, detail="Untrusted service")
    return payload
