${msg("emailVerifyGreeting", user.firstName!"there")}

${msg("passwordResetBody", realmName)}

${msg("passwordResetAction")}: ${link}

${msg("emailVerifyExpiry", linkExpirationFormatter(linkExpiration))}
${msg("passwordResetIgnore")}

-- The Write Place