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