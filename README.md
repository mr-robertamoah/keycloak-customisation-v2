# Keycloak Customisation V2

Local development stack focused on Keycloak internationalization and custom theme customization that does not rely on Keycloak parent theme markup/styles.

Includes:
- Keycloak (with custom login/email themes)
- Vue frontend (Vite)
- Auth service (FastAPI)
- Blog service (FastAPI)
- Postgres and MailHog

## Quick Start

1. Start the stack:
   - `docker compose up -d --build`
2. Open:
   - Frontend: `http://localhost:5173`
   - Keycloak: `http://localhost:8080`
   - MailHog: `http://localhost:8025`

## Detailed Setup Guide

For full, step-by-step setup and troubleshooting instructions, see:
- `GUIDE.md`
