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