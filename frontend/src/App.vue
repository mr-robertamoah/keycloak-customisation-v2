<template>
  <nav>
    <span class="brand">✍️ The Write Place</span>
    <RouterLink to="/">Home</RouterLink>
    <RouterLink v-if="user" to="/blog">My Posts</RouterLink>
    <span v-if="user" class="muted" style="margin-left:auto;">{{ user.firstName }}</span>
    <button v-if="user" @click="handleLogout">Sign out</button>
    <button v-else @click="handleLogin">Sign in</button>
  </nav>
  <RouterView />
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { RouterLink, RouterView } from 'vue-router'
import { getUserInfo, login, logout } from './keycloak.js'

const user = ref(null)
onMounted(() => { user.value = getUserInfo() })
const handleLogin  = () => login()
const handleLogout = () => logout()
</script>