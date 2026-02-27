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