# Build stage: Vite compiles the SPA to static files.
FROM node:22-alpine AS build

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# Serve stage: nginx hands out the static bundle and proxies /api to the Pharo
# service, so the browser sees one origin and CORS never enters the picture.
FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
