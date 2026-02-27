# Keycloak From Scratch — Full Theme Customisation Guide
### No Parent Theme · Complete Templates · Internationalisation (EN / FR / ES) · Vue + FastAPI · Fully Dockerised

> **What this guide does differently from typical Keycloak guides:**
> - We do **not** use `parent=keycloak`. We own every pixel.
> - We build every template ourselves so nothing is inherited and nothing surprises us.
> - We add full i18n (English, French, Spanish) so you understand how translations work.
> - Every file shown is complete and copy-paste ready.

---

## Table of Contents

1. [The Two Approaches — Explained](#1-the-two-approaches--explained)
2. [What We Are Building](#2-what-we-are-building)
3. [Prerequisites](#3-prerequisites)
4. [Complete Project Structure](#4-complete-project-structure)
5. [Docker Compose Setup](#5-docker-compose-setup)
6. [The Custom Keycloak Theme — From Scratch](#6-the-custom-keycloak-theme--from-scratch)
   - 6.1 [theme.properties — the manifest](#61-themeproperties--the-manifest)
   - 6.2 [CSS — Complete Stylesheet](#62-css--complete-stylesheet)
   - 6.3 [SVG Logo](#63-svg-logo)
   - 6.4 [login.ftl — Login Page](#64-loginftl--login-page)
   - 6.5 [register.ftl — Registration Page](#65-registerftl--registration-page)
   - 6.6 [login-reset-password.ftl — Forgot Password](#66-login-reset-passwordftl--forgot-password)
   - 6.7 [login-update-password.ftl — Set New Password](#67-login-update-passwordftl--set-new-password)
   - 6.8 [login-verify-email.ftl — Verify Email Notice](#68-login-verify-emailftl--verify-email-notice)
   - 6.9 [info.ftl — Info / Success Page](#69-infoftl--info--success-page)
   - 6.10 [error.ftl — Error Page](#610-errorftl--error-page)
7. [Internationalisation (i18n)](#7-internationalisation-i18n)
   - 7.1 [How i18n Works in Keycloak](#71-how-i18n-works-in-keycloak)
   - 7.2 [English messages](#72-english-messages)
   - 7.3 [French messages](#73-french-messages)
   - 7.4 [Spanish messages](#74-spanish-messages)
   - 7.5 [Language Switcher in Templates](#75-language-switcher-in-templates)
8. [Email Templates — From Scratch](#8-email-templates--from-scratch)
   - 8.1 [Email theme.properties](#81-email-themeproperties)
   - 8.2 [email-verification.ftl (HTML)](#82-email-verificationftl-html)
   - 8.3 [password-reset.ftl (HTML)](#83-password-resetftl-html)
   - 8.4 [Plain Text versions](#84-plain-text-versions)
   - 8.5 [Email i18n messages](#85-email-i18n-messages)
9. [FastAPI Backend Services](#9-fastapi-backend-services)
   - 9.1 [Auth Service](#91-auth-service)
   - 9.2 [Blog Service](#92-blog-service)
10. [Vue Frontend](#10-vue-frontend)
11. [Running Everything](#11-running-everything)
12. [Configuring Keycloak After Boot](#12-configuring-keycloak-after-boot)
13. [Testing Your Theme](#13-testing-your-theme)
14. [Troubleshooting](#14-troubleshooting)

---

## 1. The Two Approaches — Explained

Before writing a single file, understand the fundamental choice you are making:

### Approach A: CSS Override (parent=keycloak)

```
your-theme inherits → keycloak theme → base theme
```

You keep all of Keycloak's HTML structure, PatternFly CSS framework, and JavaScript. You only add a stylesheet that fights with `!important` to change colours, hide elements, and inject content via `::before`/`::after` pseudo-elements.

**When to use it:** You want something working in 30 minutes, your brand differences are minor (different colour, different logo), and you are comfortable fighting CSS specificity wars.

**Pain points you will hit:**
- PatternFly CSS has deeply specific selectors — you end up writing a lot of `!important`
- The parent's `login.ftl` uses its own HTML structure — your custom `login.ftl` may be ignored unless you understand the flow override system
- Upgrading Keycloak can silently break your overrides if PatternFly class names change
- You cannot control the HTML structure at all

### Approach B: Full Custom Theme (no parent / parent=base) ← **This guide**

```
your-theme inherits → base theme only
```

`parent=base` gives you access to Keycloak's core FreeMarker macros and message functions (you still need `msg()`, `url.*`, etc.) but zero PatternFly CSS or pre-built HTML. Every div, button, and form is yours.

**When to use it:** You want pixel-perfect brand control, a completely different layout, or you want to truly understand how Keycloak theming works.

**What you are responsible for:**
- All HTML structure
- All CSS (no PatternFly safety net)
- Making sure every required form field and hidden input is present
- The language switcher UI

**What `parent=base` still gives you for free:**
- The FreeMarker context variables (`url`, `realm`, `login`, `message`, etc.)
- The `msg("key")` translation function
- The `kcSanitize()` HTML sanitiser
- The `messagesPerField` per-field error helper

> **Rule of thumb:** If a designer handed you a Figma file and said "build this exactly", use Approach B. If you just need to change the logo and primary colour, use Approach A.

---

## 2. What We Are Building

A blog application called **"The Write Place"** with:

- A completely custom Keycloak login/register/email theme — no inherited PatternFly styles
- Three languages: English (default), French, Spanish — with a live language switcher on the login page
- A FastAPI **Auth Service** (validates tokens, proxies user data)
- A FastAPI **Blog Service** (manages posts, called by Auth Service internally)
- A Vue 3 SPA frontend — **served by a Docker container alongside the other services**
- Everything starts with a single `docker compose up` — no local Node.js required

---

## 3. Prerequisites

```bash
# Verify these are installed
docker --version        # >= 24
docker compose version  # >= 2.20
```

Node.js is **not** required on your machine — the frontend runs entirely inside Docker. You only need Docker.

---

## 4. Complete Project Structure

```
write-place/
│
├── docker-compose.yml
├── init.sql
│
├── keycloak/
│   └── realm-import/
│       └── write-place-realm.json
│   └── themes/
│       └── write-place/
│           ├── login/
│           │   ├── theme.properties
│           │   ├── resources/
│           │   │   ├── css/
│           │   │   │   └── theme.css
│           │   │   └── img/
│           │   │       └── logo.svg
│           │   ├── messages/
│           │   │   ├── messages_en.properties
│           │   │   ├── messages_fr.properties
│           │   │   └── messages_es.properties
│           │   ├── login.ftl
│           │   ├── register.ftl
│           │   ├── login-reset-password.ftl
│           │   ├── login-update-password.ftl
│           │   ├── login-verify-email.ftl
│           │   ├── info.ftl
│           │   └── error.ftl
│           └── email/
│               ├── theme.properties
│               ├── messages/
│               │   ├── messages_en.properties
│               │   ├── messages_fr.properties
│               │   └── messages_es.properties
│               ├── html/
│               │   ├── email-verification.ftl
│               │   └── password-reset.ftl
│               └── text/
│                   ├── email-verification.ftl
│                   └── password-reset.ftl
│
├── services/
│   ├── auth-service/
│   │   ├── Dockerfile
│   │   ├── requirements.txt
│   │   └── app/
│   │       ├── main.py
│   │       ├── auth.py
│   │       └── routers/
│   │           └── users.py
│   └── blog-service/
│       ├── Dockerfile
│       ├── requirements.txt
│       └── app/
│           ├── main.py
│           ├── auth.py
│           └── routers/
│               └── posts.py
│
└── frontend/
    ├── Dockerfile
    ├── .dockerignore
    ├── index.html
    ├── package.json
    ├── vite.config.js
    └── public/
        ├── silent-check-sso.html
    └── src/
        ├── main.js
        ├── keycloak.js
        ├── App.vue
        ├── style.css
        └── views/
            ├── Home.vue
            └── Blog.vue
```

Create the folders now:

```bash
mkdir -p write-place/keycloak/realm-import
mkdir -p write-place/keycloak/themes/write-place/login/{resources/{css,img},messages}
mkdir -p write-place/keycloak/themes/write-place/email/{messages,html,text}
mkdir -p write-place/services/{auth-service/app/routers,blog-service/app/routers}
mkdir -p write-place/frontend/{src/views,public}
cd write-place
```

---

## 5. Docker Compose Setup

### docker-compose.yml

```yaml
version: "3.9"

services:

  # ── Database ────────────────────────────────────────────────────
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U keycloak"]
      interval: 5s
      timeout: 5s
      retries: 10

  # ── Keycloak ─────────────────────────────────────────────────────
  keycloak:
    image: quay.io/keycloak/keycloak:24.0
    command:
      - start-dev
      - --import-realm
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: secret
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_HTTP_PORT: 8080
      # Disable ALL theme caching — essential for development
      KC_SPI_THEME_STATIC_MAX_AGE: -1
      KC_SPI_THEME_CACHE_THEMES: "false"
      KC_SPI_THEME_CACHE_TEMPLATES: "false"
    volumes:
      # Mount our custom theme directly into Keycloak's theme directory
      - ./keycloak/themes/write-place:/opt/keycloak/themes/write-place
      # Bootstrap realm/clients on fresh startup (ignored if realm exists).
      - ./keycloak/realm-import:/opt/keycloak/data/import
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy

  # ── Mailhog (catches all emails locally) ────────────────────────
  mailhog:
    image: mailhog/mailhog:latest
    ports:
      - "1025:1025"   # SMTP — Keycloak sends here
      - "8025:8025"   # Web UI — view emails at http://localhost:8025

  # ── Auth Service ─────────────────────────────────────────────────
  auth-service:
    build: ./services/auth-service
    environment:
      KEYCLOAK_URL: http://keycloak:8080
      KEYCLOAK_PUBLIC_URL: http://localhost:8080
      KEYCLOAK_REALM: write-place
      KEYCLOAK_CLIENT_ID: auth-service
      KEYCLOAK_CLIENT_SECRET: auth-service-secret
      BLOG_SERVICE_URL: http://blog-service:8002
    ports:
      - "8001:8001"
    depends_on:
      - keycloak
    restart: on-failure

  # ── Blog Service ─────────────────────────────────────────────────
  blog-service:
    build: ./services/blog-service
    environment:
      KEYCLOAK_URL: http://keycloak:8080
      KEYCLOAK_PUBLIC_URL: http://localhost:8080
      KEYCLOAK_REALM: write-place
      KEYCLOAK_CLIENT_ID: blog-service
      KEYCLOAK_CLIENT_SECRET: blog-service-secret
    ports:
      - "8002:8002"
    depends_on:
      - keycloak
    restart: on-failure

  # ── Frontend (Vue SPA via Vite dev server) ───────────────────────
  # The Vite dev server serves the app AND proxies API calls to the
  # backend services — so the browser only ever talks to port 5173.
  frontend:
    build: ./frontend
    ports:
      - "5173:5173"
    depends_on:
      - auth-service
      - blog-service
    # Mount source files so edits on your machine hot-reload instantly
    # inside the container without rebuilding the image.
    volumes:
      - ./frontend/src:/app/src
      - ./frontend/index.html:/app/index.html
      - ./frontend/vite.config.js:/app/vite.config.js

volumes:
  postgres_data:
```

### init.sql

```sql
-- Extra databases for our services
CREATE DATABASE auth_db;
CREATE DATABASE blog_db;
GRANT ALL PRIVILEGES ON DATABASE auth_db TO keycloak;
GRANT ALL PRIVILEGES ON DATABASE blog_db TO keycloak;
```

---

## 6. The Custom Keycloak Theme — From Scratch

### 6.1 theme.properties — the manifest

`keycloak/themes/write-place/login/theme.properties`

```properties
# ── Inheritance ──────────────────────────────────────────────────
# parent=base means: inherit ONLY the core Keycloak FreeMarker
# infrastructure (msg(), url.*, messagesPerField, etc.)
# We get ZERO PatternFly CSS, ZERO pre-built HTML. We own it all.
parent=base

# ── Stylesheets ──────────────────────────────────────────────────
# List every CSS file you want loaded, space-separated.
# Paths are relative to resources/
# IMPORTANT: Only list files that actually exist — one missing file
# silently breaks the entire theme.
styles=css/theme.css

# ── Scripts ──────────────────────────────────────────────────────
# Leave empty — we don't need extra JS for basic themes
scripts=

# ── Custom properties ────────────────────────────────────────────
# These become available in templates as ${properties.yourKey}
# Use them to avoid hardcoding values across many templates.
brandName=The Write Place
brandTagline=Where ideas find their voice
logoUrl=${resourcesPath}/img/logo.svg

# ── Internationalization ─────────────────────────────────────────
# Tell Keycloak which locales this theme supports.
# The messages/ folder must have a messages_XX.properties for each.
locales=en,fr,es
```

> **Why `parent=base` and not `parent=`(empty)?**
> Completely removing the parent breaks the `msg()` function and the FreeMarker context injection. `parent=base` is the correct way to say "I want full control but I still need Keycloak's template engine wiring."

---

### 6.2 CSS — Complete Stylesheet

`keycloak/themes/write-place/login/resources/css/theme.css`

This is the entire stylesheet. Because we own all the HTML, we do not fight specificity — we just write clean CSS.

```css
/* ═══════════════════════════════════════════════════════════════
   THE WRITE PLACE — Keycloak Login Theme
   No PatternFly. No parent CSS. We own every rule.
   ═══════════════════════════════════════════════════════════════ */

/* ── CSS Variables ──────────────────────────────────────────── */
:root {
  --brand-primary:     #6366F1;   /* indigo */
  --brand-primary-dk:  #4F46E5;
  --brand-primary-lt:  #EEF2FF;
  --brand-accent:      #F59E0B;   /* amber */
  --brand-error:       #EF4444;
  --brand-success:     #10B981;
  --brand-warning:     #F59E0B;
  --brand-info:        #3B82F6;

  --bg-page:    #F1F5F9;
  --bg-card:    #FFFFFF;
  --bg-input:   #FFFFFF;

  --text-primary:  #0F172A;
  --text-muted:    #64748B;
  --text-inverse:  #FFFFFF;

  --border:        #E2E8F0;
  --border-focus:  var(--brand-primary);

  --radius-sm: 0.375rem;
  --radius:    0.625rem;
  --radius-lg: 1rem;

  --shadow-card: 0 4px 32px rgba(99, 102, 241, 0.10),
                 0 1px 4px  rgba(0, 0, 0, 0.06);
  --shadow-btn:  0 2px 8px  rgba(99, 102, 241, 0.30);

  --font: 'Inter', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', monospace;
}

/* ── Reset ──────────────────────────────────────────────────── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

/* ── Page Layout ─────────────────────────────────────────────── */
html, body {
  min-height: 100vh;
  font-family: var(--font);
  font-size: 16px;
  color: var(--text-primary);
  background: var(--bg-page);
  -webkit-font-smoothing: antialiased;
}

/* Full-page centred layout */
.wp-page {
  min-height: 100vh;
  display: grid;
  grid-template-rows: 1fr auto;
  place-items: center;
  padding: 2rem 1rem;
  background:
    radial-gradient(ellipse 80% 50% at 50% -10%, rgba(99,102,241,0.12), transparent),
    var(--bg-page);
}

/* ── Card ────────────────────────────────────────────────────── */
.wp-card {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-card);
  width: 100%;
  max-width: 440px;
  padding: 2.5rem 2.25rem;
  border: 1px solid var(--border);
}

/* ── Brand Header ────────────────────────────────────────────── */
.wp-brand {
  text-align: center;
  margin-bottom: 2rem;
}

.wp-brand__logo {
  height: 52px;
  margin-bottom: 0.75rem;
}

.wp-brand__name {
  font-size: 1.375rem;
  font-weight: 700;
  color: var(--text-primary);
  letter-spacing: -0.02em;
}

.wp-brand__tagline {
  font-size: 0.875rem;
  color: var(--text-muted);
  margin-top: 0.25rem;
}

/* ── Page Title (under brand) ────────────────────────────────── */
.wp-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 1.5rem;
  text-align: center;
}

/* ── Alert / Message Banner ──────────────────────────────────── */
.wp-alert {
  display: flex;
  align-items: flex-start;
  gap: 0.625rem;
  padding: 0.875rem 1rem;
  border-radius: var(--radius);
  font-size: 0.875rem;
  line-height: 1.5;
  margin-bottom: 1.25rem;
}

.wp-alert__icon {
  flex-shrink: 0;
  width: 1.125rem;
  height: 1.125rem;
  margin-top: 0.1rem;
}

.wp-alert--error   { background: #FEF2F2; color: #991B1B; border: 1px solid #FECACA; }
.wp-alert--warning { background: #FFFBEB; color: #92400E; border: 1px solid #FDE68A; }
.wp-alert--success { background: #F0FDF4; color: #166534; border: 1px solid #BBF7D0; }
.wp-alert--info    { background: #EFF6FF; color: #1E40AF; border: 1px solid #BFDBFE; }

/* ── Form ────────────────────────────────────────────────────── */
.wp-form { display: flex; flex-direction: column; gap: 1.125rem; }

.wp-field { display: flex; flex-direction: column; gap: 0.375rem; }

.wp-field--row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.875rem;
}

.wp-label {
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--text-primary);
}

.wp-input {
  width: 100%;
  padding: 0.625rem 0.875rem;
  border: 1.5px solid var(--border);
  border-radius: var(--radius-sm);
  font-size: 0.9375rem;
  font-family: var(--font);
  color: var(--text-primary);
  background: var(--bg-input);
  transition: border-color 0.15s ease, box-shadow 0.15s ease;
  appearance: none;
}

.wp-input:focus {
  outline: none;
  border-color: var(--border-focus);
  box-shadow: 0 0 0 3px rgba(99, 102, 241, 0.15);
}

.wp-input--error {
  border-color: var(--brand-error);
}

.wp-input--error:focus {
  box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.15);
}

.wp-field-error {
  font-size: 0.8rem;
  color: var(--brand-error);
  display: flex;
  align-items: center;
  gap: 0.25rem;
}

/* ── Checkbox Row ────────────────────────────────────────────── */
.wp-checkbox-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.875rem;
  color: var(--text-muted);
  cursor: pointer;
  user-select: none;
}

.wp-checkbox-row input[type="checkbox"] {
  width: 1rem;
  height: 1rem;
  accent-color: var(--brand-primary);
  cursor: pointer;
  flex-shrink: 0;
}

/* ── Form Footer Row (remember me + forgot password) ────────── */
.wp-form-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: -0.25rem;
}

/* ── Buttons ─────────────────────────────────────────────────── */
.wp-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.6875rem 1.25rem;
  border: none;
  border-radius: var(--radius-sm);
  font-size: 0.9375rem;
  font-family: var(--font);
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s, box-shadow 0.15s, transform 0.1s;
  text-decoration: none;
}

.wp-btn--primary {
  width: 100%;
  background: var(--brand-primary);
  color: var(--text-inverse);
  box-shadow: var(--shadow-btn);
  margin-top: 0.25rem;
}

.wp-btn--primary:hover {
  background: var(--brand-primary-dk);
  transform: translateY(-1px);
}

.wp-btn--primary:active { transform: translateY(0); }

.wp-btn--ghost {
  background: transparent;
  color: var(--brand-primary);
  font-size: 0.875rem;
  font-weight: 500;
  padding: 0.25rem 0;
}

.wp-btn--ghost:hover { text-decoration: underline; }

/* ── Links section below the card ───────────────────────────── */
.wp-links {
  text-align: center;
  margin-top: 1.375rem;
  font-size: 0.875rem;
  color: var(--text-muted);
}

.wp-links a {
  color: var(--brand-primary);
  text-decoration: none;
  font-weight: 500;
}

.wp-links a:hover { text-decoration: underline; }

/* ── Divider ─────────────────────────────────────────────────── */
.wp-divider {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin: 0.5rem 0;
  color: var(--text-muted);
  font-size: 0.8125rem;
}

.wp-divider::before,
.wp-divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: var(--border);
}

/* ── Language Switcher ───────────────────────────────────────── */
.wp-lang-switcher {
  display: flex;
  justify-content: center;
  gap: 0.5rem;
  margin-top: 1.5rem;
  flex-wrap: wrap;
}

.wp-lang-btn {
  padding: 0.3rem 0.75rem;
  border-radius: 999px;
  font-size: 0.8rem;
  font-weight: 500;
  text-decoration: none;
  color: var(--text-muted);
  background: var(--bg-page);
  border: 1px solid var(--border);
  transition: all 0.15s;
}

.wp-lang-btn:hover,
.wp-lang-btn--active {
  background: var(--brand-primary-lt);
  color: var(--brand-primary);
  border-color: var(--brand-primary);
}

/* ── Info / Success page ─────────────────────────────────────── */
.wp-info-box {
  text-align: center;
  padding: 1rem 0;
}

.wp-info-box__icon {
  font-size: 3rem;
  margin-bottom: 1rem;
  line-height: 1;
}

.wp-info-box__title {
  font-size: 1.25rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
}

.wp-info-box__body {
  color: var(--text-muted);
  font-size: 0.9375rem;
  line-height: 1.6;
}

/* ── Password strength hint ──────────────────────────────────── */
.wp-password-hint {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-top: 0.25rem;
}

/* ── Footer ──────────────────────────────────────────────────── */
.wp-footer {
  text-align: center;
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-top: 2rem;
  padding-bottom: 1rem;
}

/* ── Responsive ──────────────────────────────────────────────── */
@media (max-width: 480px) {
  .wp-card { padding: 2rem 1.25rem; }
  .wp-field--row { grid-template-columns: 1fr; }
}
```

---

### 6.3 SVG Logo

`keycloak/themes/write-place/login/resources/img/logo.svg`

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 56" fill="none">
  <!-- Pen nib icon -->
  <rect width="44" height="44" x="6" y="6" rx="10" fill="#6366F1"/>
  <path d="M22 34 L28 16 L34 34 L28 30 Z" fill="white" stroke="white" stroke-width="1"
        stroke-linejoin="round"/>
  <circle cx="28" cy="38" r="2.5" fill="white"/>
  <!-- Brand name -->
  <text x="60" y="24" font-family="system-ui, sans-serif" font-size="14"
        font-weight="700" fill="#0F172A" letter-spacing="-0.5">The Write</text>
  <text x="60" y="42" font-family="system-ui, sans-serif" font-size="14"
        font-weight="700" fill="#6366F1" letter-spacing="-0.5">Place</text>
</svg>
```

Use command:

```bash
# Temporarily disable history expansion
set +H

cat << 'EOF' > logo.svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 56" fill="none">
  <!-- Pen nib icon -->
  <rect width="44" height="44" x="6" y="6" rx="10" fill="#6366F1"/>
  <path d="M22 34 L28 16 L34 34 L28 30 Z" fill="white" stroke="white" stroke-width="1"
        stroke-linejoin="round"/>
  <circle cx="28" cy="38" r="2.5" fill="white"/>
  <!-- Brand name -->
  <text x="60" y="24" font-family="system-ui, sans-serif" font-size="14"
        font-weight="700" fill="#0F172A" letter-spacing="-0.5">The Write</text>
  <text x="60" y="42" font-family="system-ui, sans-serif" font-size="14"
        font-weight="700" fill="#6366F1" letter-spacing="-0.5">Place</text>
</svg>
EOF

set -H
```

---

### 6.4 login.ftl — Login Page

`keycloak/themes/write-place/login/login.ftl`

```freemarker
<#-- ─────────────────────────────────────────────────────────────────
  login.ftl  —  The Write Place custom login page
  parent=base means we receive all Keycloak context variables but
  inherit NO HTML or CSS from any parent theme.

  Key variables Keycloak injects into this template:
    url.loginAction          — where the form POSTs
    url.registrationUrl      — link to register page
    url.loginResetCredentialsUrl — forgot password link
    realm.rememberMe         — bool: show "remember me"
    realm.registrationAllowed — bool: show "create account" link
    realm.resetPasswordAllowed — bool: show "forgot password" link
    realm.loginWithEmailAllowed — bool: user can log in with email
    realm.registrationEmailAsUsername — bool: email IS the username
    login.username           — pre-filled username (if any)
    login.rememberMe         — bool: remember me was previously checked
    message.type             — "error" | "warning" | "success" | "info"
    message.summary          — the message text (may contain HTML)
    messagesPerField          — per-field error helper object
    auth.showSocialProviders() — bool: any identity providers configured
    auth.providers           — list of identity providers
    locale.currentLanguageTag — e.g. "en", "fr", "es"
    locale.supported          — list of supported locale objects
─────────────────────────────────────────────────────────────────── -->
<!DOCTYPE html>
<html lang="${(locale.currentLanguageTag)!'en'}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("loginPageTitle")} — ${properties.brandName}</title>

  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
        rel="stylesheet" />

  <#-- resourcesPath is injected by Keycloak and resolves to the full
       URL of this theme's resources/ directory. Always use it. -->
  <link rel="stylesheet" href="${url.resourcesPath}/css/theme.css" />
</head>
<body>

<div class="wp-page">
  <main class="wp-card">

    <#-- ── Brand ── -->
    <div class="wp-brand">
      <img class="wp-brand__logo"
           src="${url.resourcesPath}/img/logo.svg"
           alt="${properties.brandName}" />
      <div class="wp-brand__name">${properties.brandName}</div>
      <div class="wp-brand__tagline">${msg("brandTagline")}</div>
    </div>

    <h1 class="wp-title">${msg("loginPageTitle")}</h1>

    <#-- ── Top-level alert message ──
         Keycloak sets message.type to: error | warning | success | info
         We use kcSanitize() before ?no_esc to safely allow HTML in messages -->
    <#if message?has_content>
      <div class="wp-alert wp-alert--${message.type}">
        <span class="wp-alert__icon">
          <#if message.type == "error">⛔<#elseif message.type == "warning">⚠️<#elseif message.type == "success">✅<#else>ℹ️</#if>
        </span>
        <span>${kcSanitize(message.summary)?no_esc}</span>
      </div>
    </#if>

    <#-- ── Login Form ── -->
    <form class="wp-form" action="${url.loginAction}" method="post">

      <#-- CSRF / credential ID hidden field — required by Keycloak -->
      <input type="hidden" name="credentialId"
             value="<#if auth.selectedCredential?has_content>${auth.selectedCredential}</#if>" />

      <#-- Username / Email field
           The label changes based on realm settings:
           - loginWithEmailAllowed=false → show "Username"
           - registrationEmailAsUsername=true → show "Email"
           - both true → show "Username or Email" -->
      <div class="wp-field">
        <label class="wp-label" for="username">
          <#if !realm.loginWithEmailAllowed>
            ${msg("username")}
          <#elseif !realm.registrationEmailAsUsername>
            ${msg("usernameOrEmail")}
          <#else>
            ${msg("email")}
          </#if>
        </label>
        <input
          class="wp-input <#if messagesPerField.existsError('username','password')>wp-input--error</#if>"
          type="text"
          id="username"
          name="username"
          value="${(login.username!'')}"
          autofocus
          autocomplete="username"
        />
        <#-- Per-field error — only shown when just username has an error,
             not when it's a combined "invalid credentials" error -->
        <#if messagesPerField.existsError('username') && !messagesPerField.existsError('password')>
          <span class="wp-field-error">
            ⚠ ${kcSanitize(messagesPerField.get('username'))?no_esc}
          </span>
        </#if>
      </div>

      <#-- Password field -->
      <div class="wp-field">
        <label class="wp-label" for="password">${msg("password")}</label>
        <input
          class="wp-input <#if messagesPerField.existsError('username','password')>wp-input--error</#if>"
          type="password"
          id="password"
          name="password"
          autocomplete="current-password"
        />
        <#if messagesPerField.existsError('password') && !messagesPerField.existsError('username')>
          <span class="wp-field-error">
            ⚠ ${kcSanitize(messagesPerField.get('password'))?no_esc}
          </span>
        </#if>
      </div>

      <#-- Remember me + Forgot password row -->
      <div class="wp-form-footer">
        <#if realm.rememberMe>
          <label class="wp-checkbox-row">
            <input type="checkbox" name="rememberMe"
              <#if login.rememberMe??>checked</#if> />
            ${msg("rememberMe")}
          </label>
        <#else>
          <span></span>
        </#if>

        <#if realm.resetPasswordAllowed>
          <a class="wp-btn wp-btn--ghost" href="${url.loginResetCredentialsUrl}">
            ${msg("doForgotPassword")}
          </a>
        </#if>
      </div>

      <button class="wp-btn wp-btn--primary" type="submit">
        ${msg("doLogIn")}
      </button>
    </form>

    <#-- ── Social / Identity Providers ──
         Only rendered if the realm has configured external providers
         (e.g. Google, GitHub). auth.showSocialProviders() returns true. -->
    <#if auth?? && auth.showSocialProviders?? && auth.showSocialProviders()>
      <div class="wp-divider">${msg("identity-provider-login-label")}</div>
      <#list auth.providers as provider>
        <a class="wp-btn wp-btn--primary"
           style="background:#fff;color:var(--text-primary);border:1.5px solid var(--border);
                  box-shadow:none;margin-bottom:0.5rem;"
           href="${provider.loginUrl}">
          ${provider.displayName}
        </a>
      </#list>
    </#if>

    <#-- ── Register Link ── -->
    <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
      <div class="wp-links">
        ${msg("noAccount")}
        <a href="${url.registrationUrl}">${msg("doRegister")}</a>
      </div>
    </#if>

    <#-- ── Language Switcher ──
         locale.supported is a list of objects with:
           .languageTag  — "en", "fr", "es"
           .label        — "English", "Français", "Español"
           .url          — URL to switch to that locale
         locale.currentLanguageTag — currently active locale -->
    <#if realm.internationalizationEnabled && locale?? && locale.supported?has_content>
      <div class="wp-lang-switcher">
        <#list locale.supported as lang>
          <a class="wp-lang-btn <#if lang.languageTag == ((locale.currentLanguageTag)!'en')>wp-lang-btn--active</#if>"
             href="${lang.url}">
            <#-- Map language tags to flag emojis for visual clarity -->
            <#if lang.languageTag == "en">🇬🇧<#elseif lang.languageTag == "fr">🇫🇷<#elseif lang.languageTag == "es">🇪🇸</#if>
            ${lang.label}
          </a>
        </#list>
      </div>
    </#if>

  </main>

  <footer class="wp-footer">
    &copy; ${.now?string("yyyy")} ${properties.brandName}
  </footer>
</div>

</body>
</html>
```

---

### 6.5 register.ftl — Registration Page

`keycloak/themes/write-place/login/register.ftl`

```freemarker
<#--
  register.ftl — Custom registration page

  Additional variables available on this page:
    register.formData.firstName     — submitted first name (repopulated on error)
    register.formData.lastName
    register.formData.email
    register.formData.username
    passwordRequired                — bool: show password fields
    recaptchaRequired               — bool: show Google reCAPTCHA
    recaptchaSiteKey                — public reCAPTCHA site key
-->
<!DOCTYPE html>
<html lang="${(locale.currentLanguageTag)!'en'}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("registerTitle")} — ${properties.brandName}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
        rel="stylesheet" />
  <link rel="stylesheet" href="${url.resourcesPath}/css/theme.css" />
</head>
<body>
<div class="wp-page">
  <main class="wp-card">

    <div class="wp-brand">
      <img class="wp-brand__logo" src="${url.resourcesPath}/img/logo.svg" alt="${properties.brandName}" />
      <div class="wp-brand__name">${properties.brandName}</div>
    </div>

    <h1 class="wp-title">${msg("registerTitle")}</h1>

    <#if message?has_content>
      <div class="wp-alert wp-alert--${message.type}">
        <span>${kcSanitize(message.summary)?no_esc}</span>
      </div>
    </#if>

    <#--
      IMPORTANT: The form action must be url.registrationAction.
      Keycloak signs this URL with a session code. Using any other URL
      will result in a "session expired" error.
    -->
    <form class="wp-form" action="${url.registrationAction}" method="post">

      <#-- First + Last name in a two-column row -->
      <div class="wp-field wp-field--row">
        <div class="wp-field">
          <label class="wp-label" for="firstName">${msg("firstName")}</label>
          <input
            class="wp-input <#if messagesPerField.existsError('firstName')>wp-input--error</#if>"
            type="text"
            id="firstName"
            name="firstName"
            value="${(register.formData.firstName!'')}"
            autocomplete="given-name"
          />
          <#if messagesPerField.existsError('firstName')>
            <span class="wp-field-error">⚠ ${kcSanitize(messagesPerField.get('firstName'))?no_esc}</span>
          </#if>
        </div>

        <div class="wp-field">
          <label class="wp-label" for="lastName">${msg("lastName")}</label>
          <input
            class="wp-input <#if messagesPerField.existsError('lastName')>wp-input--error</#if>"
            type="text"
            id="lastName"
            name="lastName"
            value="${(register.formData.lastName!'')}"
            autocomplete="family-name"
          />
          <#if messagesPerField.existsError('lastName')>
            <span class="wp-field-error">⚠ ${kcSanitize(messagesPerField.get('lastName'))?no_esc}</span>
          </#if>
        </div>
      </div>

      <#-- Email -->
      <div class="wp-field">
        <label class="wp-label" for="email">${msg("email")}</label>
        <input
          class="wp-input <#if messagesPerField.existsError('email')>wp-input--error</#if>"
          type="email"
          id="email"
          name="email"
          value="${(register.formData.email!'')}"
          autocomplete="email"
        />
        <#if messagesPerField.existsError('email')>
          <span class="wp-field-error">⚠ ${kcSanitize(messagesPerField.get('email'))?no_esc}</span>
        </#if>
      </div>

      <#-- Username — only shown when email is NOT used as username -->
      <#if !realm.registrationEmailAsUsername>
        <div class="wp-field">
          <label class="wp-label" for="username">${msg("username")}</label>
          <input
            class="wp-input <#if messagesPerField.existsError('username')>wp-input--error</#if>"
            type="text"
            id="username"
            name="username"
            value="${(register.formData.username!'')}"
            autocomplete="username"
          />
          <#if messagesPerField.existsError('username')>
            <span class="wp-field-error">⚠ ${kcSanitize(messagesPerField.get('username'))?no_esc}</span>
          </#if>
        </div>
      </#if>

      <#-- Password fields — only rendered when passwordRequired is set -->
      <#if passwordRequired??>
        <div class="wp-field">
          <label class="wp-label" for="password">${msg("password")}</label>
          <input
            class="wp-input <#if messagesPerField.existsError('password','password-confirm')>wp-input--error</#if>"
            type="password"
            id="password"
            name="password"
            autocomplete="new-password"
          />
          <span class="wp-password-hint">${msg("passwordHint")}</span>
          <#if messagesPerField.existsError('password')>
            <span class="wp-field-error">⚠ ${kcSanitize(messagesPerField.get('password'))?no_esc}</span>
          </#if>
        </div>

        <div class="wp-field">
          <label class="wp-label" for="password-confirm">${msg("passwordConfirm")}</label>
          <input
            class="wp-input <#if messagesPerField.existsError('password-confirm')>wp-input--error</#if>"
            type="password"
            id="password-confirm"
            name="password-confirm"
            autocomplete="new-password"
          />
          <#if messagesPerField.existsError('password-confirm')>
            <span class="wp-field-error">⚠ ${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}</span>
          </#if>
        </div>
      </#if>

      <#-- reCAPTCHA — rendered only if enabled in realm settings -->
      <#if recaptchaRequired??>
        <div class="g-recaptcha" data-sitekey="${recaptchaSiteKey}"></div>
      </#if>

      <button class="wp-btn wp-btn--primary" type="submit">
        ${msg("doRegister")}
      </button>
    </form>

    <div class="wp-links">
      ${msg("alreadyHaveAccount")}
      <a href="${url.loginUrl}">${msg("doLogIn")}</a>
    </div>

    <#if realm.internationalizationEnabled && locale?? && locale.supported?has_content>
      <div class="wp-lang-switcher">
        <#list locale.supported as lang>
          <a class="wp-lang-btn <#if lang.languageTag == ((locale.currentLanguageTag)!'en')>wp-lang-btn--active</#if>"
             href="${lang.url}">
            <#if lang.languageTag == "en">🇬🇧<#elseif lang.languageTag == "fr">🇫🇷<#elseif lang.languageTag == "es">🇪🇸</#if>
            ${lang.label}
          </a>
        </#list>
      </div>
    </#if>

  </main>
  <footer class="wp-footer">&copy; ${.now?string("yyyy")} ${properties.brandName}</footer>
</div>

<#if recaptchaRequired??>
  <script src="https://www.google.com/recaptcha/api.js" async defer></script>
</#if>
</body>
</html>
```

---

### 6.6 login-reset-password.ftl — Forgot Password

`keycloak/themes/write-place/login/login-reset-password.ftl`

```freemarker
<!DOCTYPE html>
<html lang="${(locale.currentLanguageTag)!'en'}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("emailForgotTitle")} — ${properties.brandName}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
        rel="stylesheet" />
  <link rel="stylesheet" href="${url.resourcesPath}/css/theme.css" />
</head>
<body>
<div class="wp-page">
  <main class="wp-card">

    <div class="wp-brand">
      <img class="wp-brand__logo" src="${url.resourcesPath}/img/logo.svg" alt="${properties.brandName}" />
      <div class="wp-brand__name">${properties.brandName}</div>
    </div>

    <div class="wp-info-box" style="margin-bottom:1.5rem;">
      <div class="wp-info-box__icon">🔑</div>
      <h1 class="wp-info-box__title">${msg("emailForgotTitle")}</h1>
      <p class="wp-info-box__body">${msg("emailInstruction")}</p>
    </div>

    <#if message?has_content>
      <div class="wp-alert wp-alert--${message.type}">
        ${kcSanitize(message.summary)?no_esc}
      </div>
    </#if>

    <form class="wp-form" action="${url.loginAction}" method="post">
      <div class="wp-field">
        <label class="wp-label" for="username">
          <#if !realm.loginWithEmailAllowed>
            ${msg("username")}
          <#elseif !realm.registrationEmailAsUsername>
            ${msg("usernameOrEmail")}
          <#else>
            ${msg("email")}
          </#if>
        </label>
        <input
          class="wp-input"
          type="text"
          id="username"
          name="username"
          autofocus
          value="${(auth.attemptedUsername!'')}"
          autocomplete="username"
        />
      </div>
      <button class="wp-btn wp-btn--primary" type="submit">
        ${msg("doSubmit")}
      </button>
    </form>

    <div class="wp-links">
      <a href="${url.loginUrl}">&larr; ${msg("backToLogin")}</a>
    </div>

  </main>
  <footer class="wp-footer">&copy; ${.now?string("yyyy")} ${properties.brandName}</footer>
</div>
</body>
</html>
```

---

### 6.7 login-update-password.ftl — Set New Password

`keycloak/themes/write-place/login/templates/login-update-password.ftl`

```freemarker
<#--
  Shown after the user clicks a password-reset link from their email.
  Variables:
    username — the user's username (read-only, shown for context)
-->
<!DOCTYPE html>
<html lang="${(locale.currentLanguageTag)!'en'}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("updatePasswordTitle")} — ${properties.brandName}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
        rel="stylesheet" />
  <link rel="stylesheet" href="${url.resourcesPath}/css/theme.css" />
</head>
<body>
<div class="wp-page">
  <main class="wp-card">

    <div class="wp-brand">
      <img class="wp-brand__logo" src="${url.resourcesPath}/img/logo.svg" alt="${properties.brandName}" />
    </div>

    <h1 class="wp-title">${msg("updatePasswordTitle")}</h1>

    <#if message?has_content>
      <div class="wp-alert wp-alert--${message.type}">
        ${kcSanitize(message.summary)?no_esc}
      </div>
    </#if>

    <form class="wp-form" action="${url.loginAction}" method="post">
      <input type="hidden" name="username" value="${username!''}" />
      <input type="hidden" id="id-hidden-onsubmit" name="credentialId"
             value="<#if auth.selectedCredential?has_content>${auth.selectedCredential}</#if>" />

      <div class="wp-field">
        <label class="wp-label" for="password-new">${msg("passwordNew")}</label>
        <input
          class="wp-input <#if messagesPerField.existsError('password-new','password-confirm')>wp-input--error</#if>"
          type="password"
          id="password-new"
          name="password-new"
          autofocus
          autocomplete="new-password"
        />
        <#if messagesPerField.existsError('password-new')>
          <span class="wp-field-error">⚠ ${kcSanitize(messagesPerField.get('password-new'))?no_esc}</span>
        </#if>
      </div>

      <div class="wp-field">
        <label class="wp-label" for="password-confirm">${msg("passwordConfirm")}</label>
        <input
          class="wp-input <#if messagesPerField.existsError('password-confirm')>wp-input--error</#if>"
          type="password"
          id="password-confirm"
          name="password-confirm"
          autocomplete="new-password"
        />
        <#if messagesPerField.existsError('password-confirm')>
          <span class="wp-field-error">⚠ ${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}</span>
        </#if>
      </div>

      <button class="wp-btn wp-btn--primary" type="submit">
        ${msg("doSubmit")}
      </button>
    </form>

  </main>
  <footer class="wp-footer">&copy; ${.now?string("yyyy")} ${properties.brandName}</footer>
</div>
</body>
</html>
```

---

### 6.8 login-verify-email.ftl — Verify Email Notice

`keycloak/themes/write-place/login/login-verify-email.ftl`

```freemarker
<#--
  Shown after registration when email verification is required.
  Not a form — just an information page telling the user to check their inbox.
  Variables:
    user.email — the email address we sent the verification to
-->
<!DOCTYPE html>
<html lang="${locale.currentLanguageTag}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("emailVerifyTitle")} — ${properties.brandName}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
        rel="stylesheet" />
  <link rel="stylesheet" href="${resourcesPath}/css/theme.css" />
</head>
<body>
<div class="wp-page">
  <main class="wp-card">

    <div class="wp-brand">
      <img class="wp-brand__logo" src="${properties.logoUrl}" alt="${properties.brandName}" />
    </div>

    <div class="wp-info-box">
      <div class="wp-info-box__icon">📬</div>
      <h1 class="wp-info-box__title">${msg("emailVerifyTitle")}</h1>
      <p class="wp-info-box__body">
        ${msg("emailVerifyInstruction1", user.email!"")}
      </p>
      <p class="wp-info-box__body" style="margin-top:1rem;font-size:0.875rem;">
        ${msg("emailVerifyInstruction2")}
        <a href="${url.loginAction}">${msg("doClickHere")}</a>
        ${msg("emailVerifyInstruction3")}
      </p>
    </div>

  </main>
  <footer class="wp-footer">&copy; ${.now?string("yyyy")} ${properties.brandName}</footer>
</div>
</body>
</html>
```

---

### 6.9 info.ftl — Info / Success Page

`keycloak/themes/write-place/login/info.ftl`

```freemarker
<#--
  Generic info/success page. Used by Keycloak for messages like
  "Your email has been verified" or "Password updated successfully".
  Variables:
    message.summary — the info message text
    skipLink        — if set, the "continue" link is suppressed
    actionUri       — optional URL for a continue/action button
    actionRequiredMessage — label for the action button
    client.baseUrl  — URL of the originating client app
-->
<!DOCTYPE html>
<html lang="${(locale.currentLanguageTag)!'en'}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("infoTitle")} — ${properties.brandName}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
        rel="stylesheet" />
  <link rel="stylesheet" href="${url.resourcesPath}/css/theme.css" />
</head>
<body>
<div class="wp-page">
  <main class="wp-card">

    <div class="wp-brand">
      <img class="wp-brand__logo" src="${url.resourcesPath}/img/logo.svg" alt="${properties.brandName}" />
    </div>

    <div class="wp-info-box">
      <div class="wp-info-box__icon">✅</div>
      <h1 class="wp-info-box__title">${msg("infoTitle")}</h1>
      <p class="wp-info-box__body">
        ${kcSanitize(message.summary)?no_esc}
      </p>
    </div>

    <#if !skipLink??>
      <div class="wp-links" style="margin-top:1.5rem;">
        <#if actionUri?has_content>
          <a class="wp-btn wp-btn--primary" href="${actionUri}">
            ${msg(actionRequiredMessage)}
          </a>
        <#elseif (client.baseUrl)?has_content>
          <a class="wp-btn wp-btn--primary" href="${client.baseUrl}">
            ${msg("backToApplication")}
          </a>
        </#if>
      </div>
    </#if>

  </main>
  <footer class="wp-footer">&copy; ${.now?string("yyyy")} ${properties.brandName}</footer>
</div>
</body>
</html>
```

---

### 6.10 error.ftl — Error Page

`keycloak/themes/write-place/login/error.ftl`

```freemarker
<#--
  Generic error page. Shown for OAuth errors, expired sessions, etc.
  Variables:
    message.summary — the error description
    skipLink        — if set, restart link is suppressed
    url.loginRestartFlowUrl — link to start a fresh auth flow
    client.baseUrl  — URL of the app that initiated the flow
-->
<!DOCTYPE html>
<html lang="${(locale.currentLanguageTag)!'en'}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("errorTitle")} — ${properties.brandName}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap"
        rel="stylesheet" />
  <link rel="stylesheet" href="${url.resourcesPath}/css/theme.css" />
</head>
<body>
<div class="wp-page">
  <main class="wp-card">

    <div class="wp-brand">
      <img class="wp-brand__logo" src="${url.resourcesPath}/img/logo.svg" alt="${properties.brandName}" />
    </div>

    <div class="wp-info-box">
      <div class="wp-info-box__icon">⛔</div>
      <h1 class="wp-info-box__title" style="color:var(--brand-error);">
        ${msg("errorTitle")}
      </h1>
      <p class="wp-info-box__body">
        ${kcSanitize(message.summary)?no_esc}
      </p>
    </div>

    <div class="wp-links" style="margin-top:1.5rem; display:flex; flex-direction:column; gap:0.75rem; align-items:center;">
      <#if !skipLink??>
        <a class="wp-btn wp-btn--primary" href="${url.loginRestartFlowUrl}">
          ${msg("doTryAgain")}
        </a>
      </#if>
      <#if (client.baseUrl)?has_content>
        <a class="wp-btn wp-btn--ghost" href="${client.baseUrl}">
          ${msg("backToApplication")}
        </a>
      </#if>
    </div>

  </main>
  <footer class="wp-footer">&copy; ${.now?string("yyyy")} ${properties.brandName}</footer>
</div>
</body>
</html>
```

---

## 7. Internationalisation (i18n)

### 7.1 How i18n Works in Keycloak

Here is the complete picture so nothing is a mystery:

```
1. You declare supported locales in theme.properties:
      locales=en,fr,es

2. For each locale you create a messages file:
      messages/messages_en.properties
      messages/messages_fr.properties
      messages/messages_es.properties

3. In your templates you call:
      ${msg("someKey")}
   Keycloak looks up "someKey" in the active locale's file.

4. How does Keycloak know which locale is active?
   - URL parameter: ?kc_locale=fr
   - Cookie: KC_LOCALE=fr
   - User's browser Accept-Language header
   - Realm default locale (set in admin console)

5. The language switcher renders links using ${lang.url}
   which Keycloak generates — it's the same URL with ?kc_locale=XX added.

6. Keys not found in your messages files fall back to:
      parent theme messages (base theme has English defaults)
   This means you only need to define keys you actually USE or OVERRIDE.
   But it's cleaner and more predictable to define everything yourself.
```

**Message key with substitution:**

```freemarker
<#-- In messages_en.properties: -->
emailVerifyInstruction1=An email with verification instructions was sent to {0}.

<#-- In template: -->
${msg("emailVerifyInstruction1", user.email!"")}
<#-- {0} is replaced by user.email -->
```

---

### 7.2 English messages

`keycloak/themes/write-place/login/messages/messages_en.properties`

```properties
# ── Page Titles ──────────────────────────────────────────────────
loginPageTitle=Sign in to your account
registerTitle=Create your account
emailForgotTitle=Forgot your password?
updatePasswordTitle=Set a new password
emailVerifyTitle=Verify your email
infoTitle=Done!
errorTitle=Something went wrong

# ── Field Labels ─────────────────────────────────────────────────
username=Username
email=Email address
password=Password
passwordNew=New password
passwordConfirm=Confirm password
firstName=First name
lastName=Last name
rememberMe=Remember me
usernameOrEmail=Username or email

# ── Hints ────────────────────────────────────────────────────────
passwordHint=At least 8 characters

# ── Buttons ──────────────────────────────────────────────────────
doLogIn=Sign in
doRegister=Create account
doSubmit=Send reset link
doForgotPassword=Forgot password?
doClickHere=click here

# ── Links ────────────────────────────────────────────────────────
noAccount=Don''t have an account?
alreadyHaveAccount=Already have an account?
backToLogin=Back to sign in
backToApplication=Back to app
doTryAgain=Try again

# ── Identity Providers ───────────────────────────────────────────
identity-provider-login-label=Or sign in with

# ── Instructions ─────────────────────────────────────────────────
emailInstruction=Enter your email and we''ll send you a reset link.
emailVerifyInstruction1=We sent a verification email to {0}.
emailVerifyInstruction2=Haven''t received it?
emailVerifyInstruction3=to resend.


brandTagline=Where ideas find their voice
```

> **Note the double apostrophes (`''`) in `.properties` files.** This is Java `.properties` format — a single `'` must be escaped as `''` or it will be interpreted as the start of a MessageFormat quote.

---

### 7.3 French messages

`keycloak/themes/write-place/login/messages/messages_fr.properties`

```properties
# ── Titres de page ───────────────────────────────────────────────
loginPageTitle=Connexion \u00e0 votre compte
registerTitle=Cr\u00e9er un compte
emailForgotTitle=Mot de passe oubli\u00e9 ?
updatePasswordTitle=D\u00e9finir un nouveau mot de passe
emailVerifyTitle=V\u00e9rifier votre adresse e-mail
infoTitle=C''est fait !
errorTitle=Une erreur est survenue

# ── Champs ───────────────────────────────────────────────────────
username=Nom d''utilisateur
email=Adresse e-mail
password=Mot de passe
passwordNew=Nouveau mot de passe
passwordConfirm=Confirmer le mot de passe
firstName=Pr\u00e9nom
lastName=Nom de famille
rememberMe=Se souvenir de moi
usernameOrEmail=Nom d''utilisateur ou e-mail

# ── Astuces ──────────────────────────────────────────────────────
passwordHint=Au moins 8 caract\u00e8res

# ── Boutons ──────────────────────────────────────────────────────
doLogIn=Se connecter
doRegister=Cr\u00e9er un compte
doSubmit=Envoyer le lien
doForgotPassword=Mot de passe oubli\u00e9 ?
doClickHere=cliquez ici

# ── Liens ────────────────────────────────────────────────────────
noAccount=Pas encore de compte ?
alreadyHaveAccount=D\u00e9j\u00e0 un compte ?
backToLogin=Retour \u00e0 la connexion
backToApplication=Retour \u00e0 l''application
doTryAgain=R\u00e9essayer

# ── Fournisseurs d''identit\u00e9 ─────────────────────────────────
identity-provider-login-label=Ou se connecter avec

# ── Instructions ─────────────────────────────────────────────────
emailInstruction=Saisissez votre e-mail et nous vous enverrons un lien de r\u00e9initialisation.
emailVerifyInstruction1=Nous avons envoy\u00e9 un e-mail de v\u00e9rification \u00e0 {0}.
emailVerifyInstruction2=Vous ne l''avez pas re\u00e7u ?
emailVerifyInstruction3=pour renvoyer.


brandTagline=L\u00e0 o\u00f9 les id\u00e9es trouvent leur voix
```

> **Why `\u00e9` instead of `é`?**
> Standard Java `.properties` files are ISO-8859-1 encoded. Non-ASCII characters must be written as Unicode escapes. Alternatively, save the file as UTF-8 and add `keycloak.theme.default.locale=en` — but Unicode escapes are safest for portability.

---

### 7.4 Spanish messages

`keycloak/themes/write-place/login/messages/messages_es.properties`

```properties
# ── T\u00edtulos de p\u00e1gina ─────────────────────────────────
loginPageTitle=Inicia sesi\u00f3n en tu cuenta
registerTitle=Crear una cuenta
emailForgotTitle=\u00bfOlvidaste tu contrase\u00f1a?
updatePasswordTitle=Establecer una nueva contrase\u00f1a
emailVerifyTitle=Verifica tu correo electr\u00f3nico
infoTitle=\u00a1Listo!
errorTitle=Algo sali\u00f3 mal

# ── Campos ───────────────────────────────────────────────────────
username=Nombre de usuario
email=Correo electr\u00f3nico
password=Contrase\u00f1a
passwordNew=Nueva contrase\u00f1a
passwordConfirm=Confirmar contrase\u00f1a
firstName=Nombre
lastName=Apellido
rememberMe=Recordarme
usernameOrEmail=Usuario o correo electr\u00f3nico

# ── Pistas ───────────────────────────────────────────────────────
passwordHint=M\u00ednimo 8 caracteres

# ── Botones ──────────────────────────────────────────────────────
doLogIn=Iniciar sesi\u00f3n
doRegister=Crear cuenta
doSubmit=Enviar enlace
doForgotPassword=\u00bfOlvidaste tu contrase\u00f1a?
doClickHere=haz clic aqu\u00ed

# ── Enlaces ──────────────────────────────────────────────────────
noAccount=\u00bfNo tienes cuenta?
alreadyHaveAccount=\u00bfYa tienes una cuenta?
backToLogin=Volver al inicio de sesi\u00f3n
backToApplication=Volver a la aplicaci\u00f3n
doTryAgain=Intentar de nuevo

# ── Proveedores de identidad ─────────────────────────────────────
identity-provider-login-label=O inicia sesi\u00f3n con

# ── Instrucciones ────────────────────────────────────────────────
emailInstruction=Introduce tu correo y te enviaremos un enlace para restablecer tu contrase\u00f1a.
emailVerifyInstruction1=Enviamos un correo de verificaci\u00f3n a {0}.
emailVerifyInstruction2=\u00bfNo lo recibiste?
emailVerifyInstruction3=para reenviar.


brandTagline=Donde las ideas encuentran su voz
```

---

### 7.5 Language Switcher in Templates

The language switcher you already saw in `login.ftl` is the canonical pattern. Here it is isolated for reference:

```freemarker
<#-- 
  This block goes into any template where you want a language switcher.

  locale.supported — list of supported locale objects, each has:
    .languageTag — "en", "fr", "es"
    .label       — "English", "Français", "Español" (from Keycloak's own locale names)
    .url         — full URL to switch to that locale

  locale.currentLanguageTag — the currently active locale tag

  The realm MUST have internationalizationEnabled=true and the locales
  must be in the realm's supported locales list (set in admin console).
  Your theme.properties must also list them under locales=
-->
<#if realm.internationalizationEnabled && locale?? && locale.supported?has_content>
    <div class="wp-lang-switcher">
    <#list locale.supported as lang>
        <a class="wp-lang-btn <#if lang.languageTag == ((locale.currentLanguageTag)!'en')>wp-lang-btn--active</#if>"
            href="${lang.url}">
        <#-- Map language tags to flag emojis for visual clarity -->
        <#if lang.languageTag == "en">🇬🇧<#elseif lang.languageTag == "fr">🇫🇷<#elseif lang.languageTag == "es">🇪🇸</#if>
        ${lang.label}
        </a>
    </#list>
    </div>
</#if>
```

**To activate i18n in the Keycloak admin console:**
1. Realm Settings → Localization tab
2. Toggle **Internationalization** ON
3. Under **Supported locales** add: `en`, `fr`, `es`
4. Set **Default locale** to `en`
5. Save

---

## 8. Email Templates — From Scratch

### 8.1 Email theme.properties

`keycloak/themes/write-place/email/theme.properties`

```properties
# For email we still use parent=base — it handles the raw SMTP sending
# machinery. We override ONLY the template files and messages.
parent=base

# Supported locales for email (mirrors login theme)
locales=en,fr,es
```

> Email themes can use `parent=base` even when your login theme uses no parent — the email rendering pipeline is separate.

---

### 8.2 email-verification.ftl (HTML)

`keycloak/themes/write-place/email/html/email-verification.ftl`

```freemarker
<#--
  HTML email template for the "verify your email" flow.
  Email clients are hostile to CSS — always use inline styles.
  These are the variables Keycloak provides:
    realmName       — realm display name (e.g. "Write Place")
    user.firstName  — recipient first name
    user.lastName   — recipient last name
    user.email      — recipient email
    link            — the verification URL (expires)
    linkExpiration  — expiry in minutes (integer)
    linkExpirationFormatter(n) — human-readable string, e.g. "30 minutes"
-->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("emailVerificationSubject")}</title>
</head>
<body style="margin:0;padding:0;background-color:#F1F5F9;font-family:'Helvetica Neue',Arial,sans-serif;">

  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 20px;">
    <tr>
      <td align="center">

        <!-- Card -->
        <table width="600" cellpadding="0" cellspacing="0"
               style="max-width:600px;width:100%;background:#FFFFFF;
                      border-radius:12px;overflow:hidden;
                      box-shadow:0 4px 24px rgba(99,102,241,0.10);">

          <!-- Header -->
          <tr>
            <td style="background:#6366F1;padding:32px 40px;text-align:center;">
              <div style="font-size:28px;margin-bottom:8px;">✍️</div>
              <div style="color:#FFFFFF;font-size:22px;font-weight:700;letter-spacing:-0.5px;">
                The Write Place
              </div>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:40px;">
              <p style="color:#0F172A;font-size:16px;line-height:1.6;margin:0 0 16px;">
                ${msg("emailVerifyGreeting", user.firstName!"there")}
              </p>

              <p style="color:#0F172A;font-size:15px;line-height:1.7;margin:0 0 24px;">
                ${msg("emailVerifyBody", realmName)}
              </p>

              <!-- CTA Button -->
              <table cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="center" style="padding:8px 0 32px;">
                    <a href="${link}"
                       style="display:inline-block;padding:14px 36px;
                              background:#6366F1;color:#FFFFFF;
                              text-decoration:none;border-radius:8px;
                              font-size:16px;font-weight:600;
                              letter-spacing:-0.2px;">
                      ${msg("emailVerifyAction")}
                    </a>
                  </td>
                </tr>
              </table>

              <!-- Expiry notice -->
              <div style="background:#EEF2FF;border:1px solid #C7D2FE;border-radius:8px;
                          padding:14px 18px;margin-bottom:24px;">
                <p style="margin:0;color:#3730A3;font-size:13px;line-height:1.5;">
                  ⏳ ${msg("emailVerifyExpiry", linkExpirationFormatter(linkExpiration))}
                </p>
              </div>

              <!-- Fallback link -->
              <p style="color:#64748B;font-size:13px;line-height:1.6;margin:0;">
                ${msg("emailVerifyLinkFallback")}<br/>
                <a href="${link}"
                   style="color:#6366F1;word-break:break-all;">${link}</a>
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background:#F8FAFC;padding:24px 40px;
                       border-top:1px solid #E2E8F0;text-align:center;">
              <p style="color:#94A3B8;font-size:12px;margin:0;">
                &copy; ${.now?string("yyyy")} The Write Place.
                ${msg("emailFooterIgnore")}
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

### 8.3 password-reset.ftl (HTML)

`keycloak/themes/write-place/email/html/password-reset.ftl`

```freemarker
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("passwordResetSubject")}</title>
</head>
<body style="margin:0;padding:0;background-color:#F1F5F9;font-family:'Helvetica Neue',Arial,sans-serif;">

  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 20px;">
    <tr>
      <td align="center">

        <table width="600" cellpadding="0" cellspacing="0"
               style="max-width:600px;width:100%;background:#FFFFFF;
                      border-radius:12px;overflow:hidden;
                      box-shadow:0 4px 24px rgba(99,102,241,0.10);">

          <!-- Header — red accent for password reset -->
          <tr>
            <td style="background:#EF4444;padding:32px 40px;text-align:center;">
              <div style="font-size:28px;margin-bottom:8px;">🔐</div>
              <div style="color:#FFFFFF;font-size:22px;font-weight:700;">
                ${msg("passwordResetHeader")}
              </div>
            </td>
          </tr>

          <tr>
            <td style="padding:40px;">
              <p style="color:#0F172A;font-size:16px;line-height:1.6;margin:0 0 16px;">
                ${msg("emailVerifyGreeting", user.firstName!"there")}
              </p>

              <p style="color:#0F172A;font-size:15px;line-height:1.7;margin:0 0 24px;">
                ${msg("passwordResetBody", realmName)}
              </p>

              <table cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="center" style="padding:8px 0 32px;">
                    <a href="${link}"
                       style="display:inline-block;padding:14px 36px;
                              background:#EF4444;color:#FFFFFF;
                              text-decoration:none;border-radius:8px;
                              font-size:16px;font-weight:600;">
                      ${msg("passwordResetAction")}
                    </a>
                  </td>
                </tr>
              </table>

              <div style="background:#FEF2F2;border:1px solid #FECACA;border-radius:8px;
                          padding:14px 18px;margin-bottom:24px;">
                <p style="margin:0;color:#991B1B;font-size:13px;line-height:1.5;">
                  ⚠️ ${msg("emailVerifyExpiry", linkExpirationFormatter(linkExpiration))}
                  ${msg("passwordResetIgnore")}
                </p>
              </div>

              <p style="color:#64748B;font-size:13px;line-height:1.6;margin:0;">
                ${msg("emailVerifyLinkFallback")}<br/>
                <a href="${link}" style="color:#EF4444;word-break:break-all;">${link}</a>
              </p>
            </td>
          </tr>

          <tr>
            <td style="background:#F8FAFC;padding:24px 40px;
                       border-top:1px solid #E2E8F0;text-align:center;">
              <p style="color:#94A3B8;font-size:12px;margin:0;">
                &copy; ${.now?string("yyyy")} The Write Place.
                ${msg("emailFooterIgnore")}
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
```

---

### 8.4 Plain Text versions

`keycloak/themes/write-place/email/text/email-verification.ftl`

```freemarker
${msg("emailVerifyGreeting", user.firstName!"there")}

${msg("emailVerifyBody", realmName)}

${msg("emailVerifyAction")}: ${link}

${msg("emailVerifyExpiry", linkExpirationFormatter(linkExpiration))}

${msg("emailVerifyLinkFallback")}
${link}

-- The Write Place
```

`keycloak/themes/write-place/email/text/password-reset.ftl`

```freemarker
${msg("emailVerifyGreeting", user.firstName!"there")}

${msg("passwordResetBody", realmName)}

${msg("passwordResetAction")}: ${link}

${msg("emailVerifyExpiry", linkExpirationFormatter(linkExpiration))}
${msg("passwordResetIgnore")}

-- The Write Place
```

---

### 8.5 Email i18n messages

`keycloak/themes/write-place/email/messages/messages_en.properties`

```properties
emailVerificationSubject=Verify your email — The Write Place
passwordResetSubject=Reset your password — The Write Place
passwordResetHeader=Password Reset

emailVerifyGreeting=Hi {0},
emailVerifyBody=Welcome to {0}! Click the button below to verify your email address and activate your account.
emailVerifyAction=Verify my email address
emailVerifyExpiry=This link expires in {0}.
emailVerifyLinkFallback=If the button doesn''t work, copy and paste this link:
emailFooterIgnore=If you didn''t create an account, you can safely ignore this email.

passwordResetBody=We received a request to reset the password for your {0} account.
passwordResetAction=Reset my password
passwordResetIgnore=If you didn''t request this, ignore this email — your password won''t change.
```

`keycloak/themes/write-place/email/messages/messages_fr.properties`

```properties
emailVerificationSubject=V\u00e9rifiez votre e-mail \u2014 The Write Place
passwordResetSubject=R\u00e9initialisez votre mot de passe \u2014 The Write Place
passwordResetHeader=R\u00e9initialisation du mot de passe

emailVerifyGreeting=Bonjour {0},
emailVerifyBody=Bienvenue sur {0}\u00a0! Cliquez sur le bouton ci-dessous pour v\u00e9rifier votre adresse e-mail.
emailVerifyAction=V\u00e9rifier mon adresse e-mail
emailVerifyExpiry=Ce lien expire dans {0}.
emailVerifyLinkFallback=Si le bouton ne fonctionne pas, copiez et collez ce lien\u00a0:
emailFooterIgnore=Si vous n''avez pas cr\u00e9\u00e9 de compte, ignorez cet e-mail.

passwordResetBody=Nous avons re\u00e7u une demande de r\u00e9initialisation du mot de passe de votre compte {0}.
passwordResetAction=R\u00e9initialiser mon mot de passe
passwordResetIgnore=Si vous n''avez pas fait cette demande, ignorez cet e-mail.
```

`keycloak/themes/write-place/email/messages/messages_es.properties`

```properties
emailVerificationSubject=Verifica tu correo \u2014 The Write Place
passwordResetSubject=Restablece tu contrase\u00f1a \u2014 The Write Place
passwordResetHeader=Restablecer contrase\u00f1a

emailVerifyGreeting=Hola {0},
emailVerifyBody=\u00a1Bienvenido a {0}! Haz clic en el bot\u00f3n para verificar tu direcci\u00f3n de correo.
emailVerifyAction=Verificar mi correo electr\u00f3nico
emailVerifyExpiry=Este enlace caduca en {0}.
emailVerifyLinkFallback=Si el bot\u00f3n no funciona, copia y pega este enlace:
emailFooterIgnore=Si no creaste una cuenta, ignora este correo.

passwordResetBody=Recibimos una solicitud para restablecer la contrase\u00f1a de tu cuenta en {0}.
passwordResetAction=Restablecer mi contrase\u00f1a
passwordResetIgnore=Si no solicitaste esto, ignora este correo.
```

---

## 9. FastAPI Backend Services

### 9.1 Auth Service

`services/auth-service/requirements.txt`

```
fastapi==0.111.0
uvicorn[standard]==0.30.0
python-jose[cryptography]==3.3.0
httpx==0.27.0
```

`services/auth-service/Dockerfile`

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001", "--reload"]
```

`services/auth-service/app/main.py`

```python
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
```

`services/auth-service/app/auth.py`

```python
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
```

`services/auth-service/app/routers/users.py`

```python
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
```

---

### 9.2 Blog Service

`services/blog-service/requirements.txt`

```
fastapi==0.111.0
uvicorn[standard]==0.30.0
python-jose[cryptography]==3.3.0
httpx==0.27.0
```

`services/blog-service/Dockerfile`

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8002", "--reload"]
```

`services/blog-service/app/main.py`

```python
from fastapi import FastAPI
from app.routers import posts

app = FastAPI(title="Blog Service")
app.include_router(posts.router,          prefix="/api/posts",    tags=["posts"])
app.include_router(posts.internal_router, prefix="/internal/posts", tags=["internal"])

@app.get("/health")
async def health():
    return {"status": "ok", "service": "blog-service"}
```

`services/blog-service/app/auth.py`

```python
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

```

`services/blog-service/app/routers/posts.py`

```python
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
```

---

## 10. Vue Frontend

### Why Vite inside Docker needs special configuration

When Vite runs inside a Docker container there are two things to know:

**1. Vite must bind to `0.0.0.0`, not `127.0.0.1`.**
By default Vite only listens on localhost inside the container, which Docker cannot forward to your host machine. Setting `host: true` fixes this.

**2. API calls from the browser must NOT use internal Docker hostnames.**
The browser running on your machine cannot resolve `http://auth-service:8001` — that hostname only exists inside Docker's network. The solution is a **Vite proxy**: the browser calls `http://localhost:5173/api/auth/...` and Vite rewrites it to `http://auth-service:8001/...` before forwarding, staying inside Docker's network the whole time.

```
Browser → localhost:5173/api/auth/users/me
         ↓  (Vite proxy inside Docker)
         → auth-service:8001/api/users/me   ← Docker internal DNS
```

**3. Keycloak redirects go through the browser, not through Docker.**
The Keycloak JS adapter redirects the browser to `http://localhost:8080` for login, then back to `http://localhost:5173`. These are browser-side redirects, so they must use `localhost` (your machine), not internal Docker hostnames.

---

### frontend/Dockerfile

```dockerfile
FROM node:20-alpine

WORKDIR /app

# Copy dependency manifests first — Docker caches this layer
# and only re-runs npm install when package.json changes.
COPY package.json package-lock.json* ./

RUN npm install

# Copy the rest of the source code
COPY . .

# Expose the Vite dev server port
EXPOSE 5173

# Start Vite — host:true and port are also set in vite.config.js
CMD ["npm", "run", "dev"]
```

### frontend/.dockerignore

```
node_modules
dist
.git
*.md
```

This stops Docker from copying `node_modules` from your host (if you have one) into the build context, which would conflict with the `npm install` in the Dockerfile.

---

### frontend/package.json

```json
{
  "name": "write-place-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev":   "vite",
    "build": "vite build"
  },
  "dependencies": {
    "vue":         "^3.4.0",
    "keycloak-js": "^24.0.0",
    "vue-router":  "^4.3.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^5.0.0",
    "vite": "^5.0.0"
  }
}
```

### frontend/vite.config.js

```js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],

  server: {
    // host: true makes Vite listen on 0.0.0.0 inside the container
    // so Docker can forward port 5173 to your machine.
    host: true,
    port: 5173,

    // Proxy rewrites browser API calls to internal Docker service names.
    // The browser sends: GET /api/auth/users/me
    // Vite forwards it to: http://auth-service:8001/api/users/me
    // Rewrite /api/auth/* -> /api/* and /api/blog/* -> /api/*
    proxy: {
      '/api/auth': {
        target:   'http://auth-service:8001',
        changeOrigin: true,
        rewrite:  (path) => path.replace(/^\/api\/auth/, '/api'),
      },
      '/api/blog': {
        target:   'http://blog-service:8002',
        changeOrigin: true,
        rewrite:  (path) => path.replace(/^\/api\/blog/, '/api'),
      },
    },
  },
})
```

`frontend/index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
  <title>The Write Place</title>
</head>
<body>
  <div id="app"></div>
  <script type="module" src="/src/main.js"></script>
</body>
</html>
```

`frontend/public/silent-check-sso.html`

```html
<!DOCTYPE html>
<html><body>
<script>parent.postMessage(location.href, location.origin)</script>
</body></html>
```

`frontend/src/keycloak.js`

```js
import Keycloak from 'keycloak-js'

const keycloakConfig = {
  url:      'http://localhost:8080',
  realm:    'write-place',
  clientId: 'write-place-frontend',
}
const keycloak = new Keycloak(keycloakConfig)

let _init = null

export function initKeycloak() {
  if (_init) return _init

  const keycloakOrigin = new URL(keycloakConfig.url).origin
  const sameOrigin = window.location.origin === keycloakOrigin
  const initOptions = {
    onLoad: 'check-sso',
    pkceMethod: 'S256',
    checkLoginIframe: false,
    // On a different origin (localhost:5173 -> localhost:8080), Keycloak's
    // 3p cookie probe iframe can be blocked by CSP and reject init.
    // Keep check-sso but avoid silent iframe mode in that case.
    ...(sameOrigin
      ? { silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html' }
      : { silentCheckSsoFallback: false }),
  }

  _init = keycloak.init(initOptions).catch((error) => {
    const code = String(error?.error || '')
    const message = String(error?.error || error?.message || error || '')
    if (code === 'login_required') {
      // check-sso can return login_required after logout; treat as logged-out.
      return false
    }
    if (message.includes('3rd party check iframe')) {
      console.warn('Keycloak 3rd-party iframe check failed; continuing unauthenticated.')
      return false
    }
    throw error
  })
  keycloak.onTokenExpired = () =>
    keycloak.updateToken(70).catch(() => keycloak.logout())
  return _init
}

export const login  = ()  => keycloak.login()
export const logout = ()  => keycloak.logout({ redirectUri: window.location.origin })
export const getToken    = () => keycloak.token
export const isLoggedIn  = () => !!keycloak.token
export const getUserInfo = () => {
  if (!keycloak.tokenParsed) return null
  return {
    id:        keycloak.tokenParsed.sub,
    email:     keycloak.tokenParsed.email,
    username:  keycloak.tokenParsed.preferred_username,
    firstName: keycloak.tokenParsed.given_name,
    lastName:  keycloak.tokenParsed.family_name,
  }
}
```

`frontend/src/main.js`

```js
import { createApp }    from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App              from './App.vue'
import Home             from './views/Home.vue'
import Blog             from './views/Blog.vue'
import { initKeycloak, isLoggedIn, login } from './keycloak.js'
import './style.css'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: Home },
    {
      path: '/blog',
      component: Blog,
      beforeEnter: (_to, _from, next) => {
        isLoggedIn() ? next() : login()
      },
    },
  ],
})

initKeycloak()
  .catch((error) => {
    // Avoid a blank page if keycloak init fails unexpectedly.
    console.warn('Keycloak init failed; loading app in logged-out mode.', error)
  })
  .finally(() => {
    createApp(App).use(router).mount('#app')
  })
```

`frontend/src/style.css`

```css
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body {
  font-family: 'Inter', system-ui, sans-serif;
  background: #F8FAFC;
  color: #0F172A;
}
nav {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  padding: 0 2rem;
  height: 60px;
  background: #fff;
  border-bottom: 1px solid #E2E8F0;
  box-shadow: 0 1px 4px rgba(0,0,0,0.05);
}
nav .brand { font-weight: 700; color: #6366F1; font-size: 1.1rem; margin-right: auto; }
nav a { color: #64748B; text-decoration: none; font-size: 0.9rem; font-weight: 500; }
nav a:hover { color: #6366F1; }
nav button {
  padding: 0.45rem 1rem;
  background: #6366F1;
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 0.875rem;
  font-weight: 600;
  cursor: pointer;
}
nav button:hover { background: #4F46E5; }
main { max-width: 860px; margin: 0 auto; padding: 2.5rem 1.5rem; }
h1 { font-size: 1.75rem; font-weight: 700; margin-bottom: 1.5rem; }
.card {
  background: #fff;
  border: 1px solid #E2E8F0;
  border-radius: 10px;
  padding: 1.5rem;
  margin-bottom: 1rem;
}
.card h3 { font-size: 1.1rem; margin-bottom: 0.5rem; }
.card p  { color: #64748B; font-size: 0.9rem; line-height: 1.6; }
.form-group { display: flex; flex-direction: column; gap: 0.5rem; margin-bottom: 1rem; }
.form-group label { font-size: 0.875rem; font-weight: 500; }
.form-group input, .form-group textarea {
  padding: 0.6rem 0.875rem;
  border: 1.5px solid #E2E8F0;
  border-radius: 6px;
  font-size: 0.9375rem;
  font-family: inherit;
  resize: vertical;
}
.form-group input:focus, .form-group textarea:focus {
  outline: none;
  border-color: #6366F1;
  box-shadow: 0 0 0 3px rgba(99,102,241,0.12);
}
.btn {
  padding: 0.65rem 1.25rem;
  background: #6366F1;
  color: #fff;
  border: none;
  border-radius: 6px;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
}
.btn:hover { background: #4F46E5; }
.error { color: #EF4444; font-size: 0.875rem; margin-bottom: 1rem; }
.muted { color: #94A3B8; font-size: 0.875rem; }
```

`frontend/src/App.vue`

```vue
<template>
  <nav>
    <span class="brand">✍️ The Write Place</span>
    <RouterLink to="/">Home</RouterLink>
    <RouterLink v-if="user" to="/blog">My Posts</RouterLink>
    <span v-if="user" class="muted" style="margin-left:auto;">{{ user.firstName }}</span>
    <button v-if="user" @click="handleLogout">Sign out</button>
    <button v-else @click="handleLogin">Sign in</button>
  </nav>
  <RouterView />
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink, RouterView } from 'vue-router'
import { getUserInfo, login, logout } from './keycloak.js'

const user = ref(null)
onMounted(() => { user.value = getUserInfo() })
const handleLogin  = () => login()
const handleLogout = () => logout()
</script>
```

`frontend/src/views/Home.vue`

```vue
<template>
  <main>
    <h1>Welcome to The Write Place</h1>
    <div class="card">
      <h3>Share your ideas with the world</h3>
      <p>
        Sign in or create an account to start publishing blog posts.
        The login page is fully custom — no PatternFly, no inherited styles.
      </p>
    </div>
  </main>
</template>
```

`frontend/src/views/Blog.vue`

```vue
<template>
  <main>
    <h1>My Posts</h1>

    <div v-if="error" class="error">{{ error }}</div>

    <form @submit.prevent="createPost" style="margin-bottom:2rem;">
      <div class="form-group">
        <label>Title</label>
        <input v-model="form.title" placeholder="Post title" required />
      </div>
      <div class="form-group">
        <label>Content</label>
        <textarea v-model="form.content" rows="4" placeholder="Write something..." required></textarea>
      </div>
      <button class="btn" type="submit" :disabled="saving">
        {{ saving ? 'Publishing...' : 'Publish' }}
      </button>
    </form>

    <div v-if="loading" class="muted">Loading posts...</div>

    <div v-for="post in posts" :key="post.id" class="card">
      <h3>{{ post.title }}</h3>
      <p>{{ post.content }}</p>
      <p class="muted" style="margin-top:0.5rem;">{{ post.created_at }}</p>
    </div>

    <p v-if="!loading && posts.length === 0" class="muted">No posts yet. Write your first one!</p>
  </main>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getToken } from '../keycloak.js'

const posts   = ref([])
const loading = ref(true)
const saving  = ref(false)
const error   = ref(null)
const form    = ref({ title: '', content: '' })

function api(url, opts = {}) {
  return fetch(url, {
    ...opts,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${getToken()}`,
      ...opts.headers,
    },
  })
}

onMounted(async () => {
  try {
    const r = await api('/api/auth/users/me/posts')
    if (!r.ok) throw new Error(`HTTP ${r.status}`)
    posts.value = await r.json()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
})

async function createPost() {
  saving.value = true
  error.value  = null
  try {
    const r = await api('/api/blog/posts', {
      method: 'POST',
      body: JSON.stringify({ ...form.value, published: true }),
    })
    if (!r.ok) throw new Error(`HTTP ${r.status}`)
    posts.value.unshift(await r.json())
    form.value = { title: '', content: '' }
  } catch (e) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}
</script>
```

---

## 11. Running Everything

Everything — Keycloak, Postgres, Mailhog, Auth Service, Blog Service, and the Vue frontend — starts with one command:

```bash
cd write-place
docker compose up -d
```

Watch the startup sequence:

```bash
docker compose logs -f
```

Services come up in this order (controlled by `depends_on`):

```
postgres    → healthy
keycloak    → starts (needs postgres)
mailhog     → starts immediately
auth-service  → starts (needs keycloak)
blog-service  → starts (needs keycloak)
frontend      → starts (needs auth-service, blog-service)
```

Keycloak takes the longest — about 30–60 seconds. Wait until you see this in the logs before proceeding:

```
keycloak  | Running the server in development mode.
keycloak  | Listening on: http://0.0.0.0:8080
```

Then check all services are up:

```bash
docker compose ps
# Every service should show "running"
```

**Service URLs once everything is up:**

| Service | URL |
|---|---|
| Vue frontend | http://localhost:5173 |
| Keycloak admin | http://localhost:8080 |
| Mailhog (email viewer) | http://localhost:8025 |
| Auth Service | http://localhost:8001 |
| Blog Service | http://localhost:8002 |

### Hot-reloading frontend changes

Because `docker-compose.yml` mounts `./frontend/src` and `./frontend/index.html` as volumes into the container, **any edit you make to a `.vue` or `.js` file on your machine is instantly picked up by the Vite server inside Docker** — no rebuild, no restart needed. Just save the file and the browser refreshes automatically.

```bash
# If you add a new dependency to package.json you DO need to rebuild:
docker compose build frontend
docker compose up -d frontend
```

---

## 12. Configuring Keycloak After Boot

Open `http://localhost:8080` → sign in with `admin` / `admin`.

### 12.1 Create a Realm

1. Click the realm dropdown (top-left) → **Create realm**
2. Realm name: `write-place`
3. Display name: `The Write Place`
4. Click **Create**

### 12.2 Enable Internationalisation

1. **Realm Settings** → **Localization** tab
2. Toggle **Internationalization** → ON
3. Supported locales: add `en`, `fr`, `es`
4. Default locale: `en`
5. **Save**

### 12.3 Apply the Custom Theme

1. **Realm Settings** → **Themes** tab
2. Login theme: `write-place`
3. Email theme: `write-place`
4. **Save**

### 12.4 Configure SMTP (for email testing)

1. **Realm Settings** → **Email** tab
2. From: `noreply@writeplace.local`
3. Host: `mailhog`
4. Port: `1025`
5. Leave SSL/TLS OFF
6. **Save**

Click **Test connection** — check `http://localhost:8025` for the test email.

### 12.5 Enable User Registration & Email Verification

1. **Realm Settings** → **Login** tab
2. User registration: **ON**
3. Email as username: your preference (ON = simpler for users)
4. Verify email: **ON** (triggers email-verification.ftl)
5. **Save**

### 12.6 Create the Frontend Client

1. **Clients** → **Create client**
2. Client type: `OpenID Connect`
3. Client ID: `write-place-frontend`
4. **Next**
5. Standard flow: **ON**, Direct access grants: **OFF**
6. **Next**
7. Valid redirect URIs: `http://localhost:5173/*`
8. Valid post-logout redirect URIs: `http://localhost:5173`
9. Web origins: `http://localhost:5173`
10. **Save**

### 12.7 Create the Auth Service Client

1. **Clients** → **Create client**
2. Client ID: `auth-service`
3. **Next**
4. Client authentication: **ON**
5. Service accounts roles: **ON**
6. **Next** → **Save**
7. **Credentials** tab → copy the client secret
8. Update `docker-compose.yml` → `KEYCLOAK_CLIENT_SECRET: <paste here>`

### 12.8 Create the Blog Service Client

Same steps as auth-service but Client ID: `blog-service`. Copy its secret too.

### 12.9 Restart Services with Updated Secrets

```bash
docker compose restart auth-service blog-service frontend
```

---

Another option is also to import the realm configuration to the /opt/keycloak/data/import directory of the keycloak container as seen in the `docker-compose.yaml` file

```yaml
services:

  <!-- other services above -->

  # ── Keycloak ─────────────────────────────────────────────────────
  keycloak:
    image: quay.io/keycloak/keycloak:24.0
    command:
      - start-dev
      - --import-realm
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: secret
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
      KC_HTTP_PORT: 8080
      # Disable ALL theme caching — essential for development
      KC_SPI_THEME_STATIC_MAX_AGE: -1
      KC_SPI_THEME_CACHE_THEMES: "false"
      KC_SPI_THEME_CACHE_TEMPLATES: "false"
    volumes:
      # Mount our custom theme directly into Keycloak's theme directory
      - ./keycloak/themes/write-place:/opt/keycloak/themes/write-place
      # Bootstrap realm/clients on fresh startup (ignored if realm exists).
      - ./keycloak/realm-import:/opt/keycloak/data/import
    ports:
      - "8080:8080"
    depends_on:
      postgres:
        condition: service_healthy

    <!-- other services below -->

```

---

## 13. Testing Your Theme

### See the login page

Open `http://localhost:5173` in your browser and click **Sign in**. Or go directly to:

```
http://localhost:8080/realms/write-place/protocol/openid-connect/auth?client_id=write-place-frontend&redirect_uri=http://localhost:5173&response_type=code
```

### Test the language switcher

Click 🇫🇷 on the login page — all labels should switch to French instantly without a page reload of your app. Click 🇪🇸 for Spanish.

### Test registration

1. Click **Create account** on the login page
2. Fill in the form and submit
3. Check Mailhog at `http://localhost:8025` for the verification email
4. Click the link in the email — it runs `login-verify-email.ftl` then `info.ftl`

### Test forgot password

1. On the login page click **Forgot password?**
2. Enter your email
3. Check Mailhog for the reset email
4. Click the link — it runs `login-update-password.ftl`

### Hot reload during development

Because you set these in `docker-compose.yml`:

```yaml
KC_SPI_THEME_CACHE_THEMES: "false"
KC_SPI_THEME_CACHE_TEMPLATES: "false"
```

You can **edit any `.ftl` or `.css` or `.properties` file and simply refresh the browser** — no Keycloak restart needed.

Verify files are reaching the container:

```bash
docker compose exec keycloak ls /opt/keycloak/themes/write-place/login/
docker compose exec keycloak cat /opt/keycloak/themes/write-place/login/theme.properties
```

---

## 14. Troubleshooting

| Symptom | Most likely cause | Fix |
|---|---|---|
| Theme not in admin dropdown | Directory name doesn't match OR `theme.properties` missing | Check `ls keycloak/themes/write-place/login/theme.properties` |
| Page shows Keycloak default theme | Theme not selected in realm settings | Realm Settings → Themes → set Login theme to `write-place` |
| CSS not loading / 404 | `theme.properties` lists a CSS file that doesn't exist | Check `styles=css/theme.css` matches your actual file name exactly |
| `msg("key")` renders literally as the key | Messages file missing or key not defined | Check `messages/messages_en.properties` exists and has the key |
| Language switcher not showing | i18n not enabled in realm | Realm Settings → Localization → toggle ON, add locales |
| Email not arriving | SMTP not configured | Set mailhog SMTP in Realm Settings → Email |
| `NullPointerException` in FreeMarker | Accessing a variable that can be null | Use `${var!"default"}` or `<#if var?has_content>` |
| Login form submits but loops back | Missing hidden `credentialId` field | Ensure your `login.ftl` has `<input type="hidden" name="credentialId" ...>` |
| Registration form gives "session expired" | Wrong form action URL | Use `${url.registrationAction}` not `${url.loginAction}` |
| `401` from backend | Token expired or wrong issuer | Check Keycloak URL and realm name in service env vars |
| Auth service can't reach Keycloak | Service started before Keycloak was ready | `docker compose restart auth-service blog-service` |
| Frontend container exits immediately | npm install failed during build | Run `docker compose build frontend` and check the output for errors |
| `http://localhost:5173` shows blank page | Frontend container not running | Check `docker compose ps` — if frontend is stopped, run `docker compose logs frontend` |
| API calls return `502 Bad Gateway` | Vite proxy can't reach the backend service | Check `docker compose ps` — ensure auth-service and blog-service are running |
| Changes to `.vue` files not hot-reloading | Volume mount not working | Confirm `./frontend/src:/app/src` is in docker-compose.yml volumes for frontend |
| Frontend can't connect to Keycloak | Browser uses `localhost:8080`, not internal hostname | `keycloak.js` must use `http://localhost:8080`, not `http://keycloak:8080` — the browser makes this call, not the container |

---

*Guide complete. You now have a fully self-contained project with a ground-up Keycloak theme, three-language i18n, email templates, and a working Vue + FastAPI application — every service including the frontend running from a single `docker compose up`.*