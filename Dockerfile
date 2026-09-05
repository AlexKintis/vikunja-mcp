# ==========================================
# Stage 1: Build & Compile TypeScript
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

# Install native compilation dependencies and git
RUN apk add --no-cache python3 make g++ git

# Copy package descriptors first for Docker layer caching
COPY package*.json ./

# Install dependencies safely:
# - legacy-peer-deps avoids npm ERESOLVE strictness
# - ignore-scripts prevents prepare/postinstall scripts from failing before src is copied
RUN npm install --legacy-peer-deps --ignore-scripts

# Copy TypeScript configuration and source files
COPY tsconfig*.json ./
COPY src/ ./src/

# Compile TypeScript source code into dist/
RUN npm run build

# Prune development dependencies to keep the image slim
RUN npm prune --production --legacy-peer-deps --ignore-scripts

# ==========================================
# Stage 2: Lightweight Production Runtime
# ==========================================
FROM node:20-alpine AS runner

ENV NODE_ENV=production

WORKDIR /app

# Run as an unprivileged user for runtime security
USER node

# Copy production artifacts and node_modules from builder
COPY --chown=node:node --from=builder /app/package*.json ./
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/dist ./dist

ENTRYPOINT ["node", "dist/index.js"]
