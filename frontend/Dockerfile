FROM node:20-alpine

WORKDIR /app

# Copy dependency manifests first — Docker caches this layer
# and only re-runs npm install when package.json changes.
COPY package.json package-lock.json* ./

RUN npm install

# Copy the rest of the source code
COPY . .

# Expose the Vite dev server port
EXPOSE 5173

# Start Vite — host:true and port are also set in vite.config.js
CMD ["npm", "run", "dev"]