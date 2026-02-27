${msg("emailVerifyGreeting", user.firstName!"there")}

${msg("emailVerifyBody", realmName)}

${msg("emailVerifyAction")}: ${link}

${msg("emailVerifyExpiry", linkExpirationFormatter(linkExpiration))}

${msg("emailVerifyLinkFallback")}
${link}

-- The Write Place