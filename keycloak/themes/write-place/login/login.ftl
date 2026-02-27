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
