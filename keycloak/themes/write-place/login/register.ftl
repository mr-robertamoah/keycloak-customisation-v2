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
