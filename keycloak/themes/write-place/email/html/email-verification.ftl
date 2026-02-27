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
                  ⏳ ${msg("emailVerifyExpiry", linkExpirationFormatter(linkElinkExpirationxpiration))}
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