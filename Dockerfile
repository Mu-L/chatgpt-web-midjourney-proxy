# build front-end
FROM node:lts-alpine AS frontend

RUN npm install pnpm -g
# 安装 Git
RUN apk add --no-cache git

WORKDIR /app

COPY ./package.json /app

COPY ./pnpm-lock.yaml /app

RUN pnpm install --no-frozen-lockfile

COPY . /app

RUN pnpm run build

# build backend
FROM node:lts-alpine AS backend

RUN npm install pnpm -g

WORKDIR /app

COPY /service/package.json /app

COPY /service/pnpm-lock.yaml /app

RUN pnpm install --no-frozen-lockfile

COPY /service /app

RUN pnpm build

# service
FROM node:lts-alpine

RUN npm install pnpm -g

WORKDIR /app

COPY /service/package.json /app

COPY /service/pnpm-lock.yaml /app

RUN pnpm install --prod --no-frozen-lockfile \
 && rm -rf /root/.npm /root/.pnpm-store /usr/local/share/.cache /tmp/*

COPY /service /app

COPY --from=frontend /app/dist /app/public

COPY --from=backend /app/build /app/build

EXPOSE 3002

CMD ["pnpm", "run", "prod"]
