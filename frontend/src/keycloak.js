import Keycloak from 'keycloak-js'

const keycloakConfig = {
  url:      'http://localhost:8080',
  realm:    'write-place',
  clientId: 'write-place-frontend',
}
const keycloak = new Keycloak(keycloakConfig)

let _init = null

export function initKeycloak() {
  if (_init) return _init

  const keycloakOrigin = new URL(keycloakConfig.url).origin
  const sameOrigin = window.location.origin === keycloakOrigin
  const initOptions = {
    onLoad: 'check-sso',
    pkceMethod: 'S256',
    checkLoginIframe: false,
    // On a different origin (localhost:5173 -> localhost:8080), Keycloak's
    // 3p cookie probe iframe can be blocked by CSP and reject init.
    // Keep check-sso but avoid silent iframe mode in that case.
    ...(sameOrigin
      ? { silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html' }
      : { silentCheckSsoFallback: false }),
  }

  _init = keycloak.init(initOptions).catch((error) => {
    const code = String(error?.error || '')
    const message = String(error?.error || error?.message || error || '')
    if (code === 'login_required') {
      // check-sso can return login_required after logout; treat as logged-out.
      return false
    }
    if (message.includes('3rd party check iframe')) {
      console.warn('Keycloak 3rd-party iframe check failed; continuing unauthenticated.')
      return false
    }
    throw error
  })
  keycloak.onTokenExpired = () =>
    keycloak.updateToken(70).catch(() => keycloak.logout())
  return _init
}

export const login  = ()  => keycloak.login()
export const logout = ()  => keycloak.logout({ redirectUri: window.location.origin })
export const getToken    = () => keycloak.token
export const isLoggedIn  = () => !!keycloak.token
export const getUserInfo = () => {
  if (!keycloak.tokenParsed) return null
  return {
    id:        keycloak.tokenParsed.sub,
    email:     keycloak.tokenParsed.email,
    username:  keycloak.tokenParsed.preferred_username,
    firstName: keycloak.tokenParsed.given_name,
    lastName:  keycloak.tokenParsed.family_name,
  }
}
