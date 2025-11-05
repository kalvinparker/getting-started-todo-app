# Stage 0: Define the secure base image
FROM node:22-alpine AS base
WORKDIR /usr/local/app

# --- CLIENT STAGES (No change needed) ---
FROM base AS client-base
COPY client/package.json client/package-lock.json ./
RUN npm install
COPY client/.eslintrc.cjs client/index.html client/vite.config.js ./
COPY client/public ./public
COPY client/src ./src

FROM client-base AS client-build
RUN npm run build

# --- BACKEND STAGES (REMEDIATED) ---
FROM base AS backend-dev
COPY backend/package.json backend/package-lock.json ./

# FIX 1: Install build tools for Alpine Linux ('apk' not 'apt-get')
RUN apk add --no-cache build-base python3

# FIX 2: Update dependencies to patch vulnerabilities before installing
RUN npm update
RUN npm install

COPY backend/spec ./spec
COPY backend/src ./src

# --- FINAL STAGE (REMEDIATED) ---
FROM base AS final
ENV NODE_ENV=production
COPY --from=backend-dev /usr/local/app/package.json /usr/local/app/package-lock.json ./

# FIX 1 & 2: Install build tools, run a clean production install with updated deps, then remove build tools
RUN apk add --no-cache build-base python3 && \
    npm ci --production && \
    npm cache clean --force && \
    apk del build-base python3

COPY backend/src ./src
COPY --from=client-build /usr/local/app/dist ./src/static
EXPOSE 3000
CMD ["node", "src/index.js"]