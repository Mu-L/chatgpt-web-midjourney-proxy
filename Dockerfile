# =========================
# frontend build
# =========================
FROM node:20-alpine AS frontend

# git 有些依赖会需要
RUN apk add --no-cache git libc6-compat

# 使用 corepack 管理 pnpm（官方推荐）
RUN corepack enable

WORKDIR /app

COPY package.json pnpm-lock.yaml ./

# 允许 postinstall scripts
RUN pnpm install --frozen-lockfile --ignore-scripts=false

COPY . .

RUN pnpm run build


# =========================
# backend build
# =========================
FROM node:20-alpine AS backend

RUN apk add --no-cache libc6-compat

RUN corepack enable

WORKDIR /app

COPY service/package.json service/pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile --ignore-scripts=false

COPY service/ .

RUN pnpm build


# =========================
# production runtime
# =========================
FROM node:20-alpine

RUN apk add --no-cache libc6-compat

RUN corepack enable

ENV NODE_ENV=production

WORKDIR /app

COPY service/package.json service/pnpm-lock.yaml ./

# 生产依赖
RUN pnpm install --prod --frozen-lockfile --ignore-scripts=false \
    && rm -rf /root/.npm \
    && rm -rf /root/.pnpm-store \
    && rm -rf /usr/local/share/.cache \
    && rm -rf /tmp/*

# backend source
COPY service/ .

# frontend dist
COPY --from=frontend /app/dist /app/public

# compiled backend
COPY --from=backend /app/build /app/build

EXPOSE 3002

CMD ["pnpm", "run", "prod"]