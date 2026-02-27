import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],

  server: {
    // host: true makes Vite listen on 0.0.0.0 inside the container
    // so Docker can forward port 5173 to your machine.
    host: true,
    port: 5173,

    // Proxy rewrites browser API calls to internal Docker service names.
    // The browser sends: GET /api/auth/users/me
    // Vite forwards it to: http://auth-service:8001/api/users/me
    // Rewrite /api/auth/* -> /api/* and /api/blog/* -> /api/*
    proxy: {
      '/api/auth': {
        target:   'http://auth-service:8001',
        changeOrigin: true,
        rewrite:  (path) => path.replace(/^\/api\/auth/, '/api'),
      },
      '/api/blog': {
        target:   'http://blog-service:8002',
        changeOrigin: true,
        rewrite:  (path) => path.replace(/^\/api\/blog/, '/api'),
      },
    },
  },
})
