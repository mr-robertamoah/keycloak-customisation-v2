<template>
  <main>
    <h1>My Posts</h1>

    <div v-if="error" class="error">{{ error }}</div>

    <form @submit.prevent="createPost" style="margin-bottom:2rem;">
      <div class="form-group">
        <label>Title</label>
        <input v-model="form.title" placeholder="Post title" required />
      </div>
      <div class="form-group">
        <label>Content</label>
        <textarea v-model="form.content" rows="4" placeholder="Write something..." required></textarea>
      </div>
      <button class="btn" type="submit" :disabled="saving">
        {{ saving ? 'Publishing...' : 'Publish' }}
      </button>
    </form>

    <div v-if="loading" class="muted">Loading posts...</div>

    <div v-for="post in posts" :key="post.id" class="card">
      <h3>{{ post.title }}</h3>
      <p>{{ post.content }}</p>
      <p class="muted" style="margin-top:0.5rem;">{{ post.created_at }}</p>
    </div>

    <p v-if="!loading && posts.length === 0" class="muted">No posts yet. Write your first one!</p>
  </main>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getToken } from '../keycloak.js'

const posts   = ref([])
const loading = ref(true)
const saving  = ref(false)
const error   = ref(null)
const form    = ref({ title: '', content: '' })

function api(url, opts = {}) {
  return fetch(url, {
    ...opts,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${getToken()}`,
      ...opts.headers,
    },
  })
}

onMounted(async () => {
  try {
    const r = await api('/api/auth/users/me/posts')
    if (!r.ok) throw new Error(`HTTP ${r.status}`)
    posts.value = await r.json()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
})

async function createPost() {
  saving.value = true
  error.value  = null
  try {
    const r = await api('/api/blog/posts', {
      method: 'POST',
      body: JSON.stringify({ ...form.value, published: true }),
    })
    if (!r.ok) throw new Error(`HTTP ${r.status}`)
    posts.value.unshift(await r.json())
    form.value = { title: '', content: '' }
  } catch (e) {
    error.value = e.message
  } finally {
    saving.value = false
  }
}
</script>
