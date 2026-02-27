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