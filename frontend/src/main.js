import { createApp }    from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App              from './App.vue'
import Home             from './views/Home.vue'
import Blog             from './views/Blog.vue'
import { initKeycloak, isLoggedIn, login } from './keycloak.js'
import './style.css'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: Home },
    {
      path: '/blog',
      component: Blog,
      beforeEnter: (_to, _from, next) => {
        isLoggedIn() ? next() : login()
      },
    },
  ],
})

initKeycloak()
  .catch((error) => {
    // Avoid a blank page if keycloak init fails unexpectedly.
    console.warn('Keycloak init failed; loading app in logged-out mode.', error)
  })
  .finally(() => {
    createApp(App).use(router).mount('#app')
  })
