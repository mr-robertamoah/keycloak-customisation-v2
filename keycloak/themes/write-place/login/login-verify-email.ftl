<#--
  Shown after registration when email verification is required.
  Not a form — just an information page telling the user to check their inbox.
  Variables:
    user.email — the email address we sent the verification to
-->
<!DOCTYPE html>
<html lang="${(locale.currentLanguageTag)!'en'}">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${msg("emailVerifyTitle")} — ${properties.brandName}</title>
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