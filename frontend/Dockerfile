# La app usa vistas renderizadas en servidor; esta etapa arma los assets estáticos.
FROM node:22-alpine AS assets
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY src ./src
COPY test ./test
COPY .c8rc.json ./.c8rc.json
COPY public ./public
RUN npm run build

# La misma receta del Dockerfile verifica la lógica de telemetría antes de publicar.
FROM assets AS test
ENTRYPOINT ["npm", "run", "test:check-coverage"]

# Nginx sirve CSS y actúa como entrada única hacia el backend Express.
FROM nginx:1.29-alpine AS runtime
LABEL org.opencontainers.image.source="https://github.com/LautyUCC/ingesoft3"
LABEL org.opencontainers.image.description="Frontend Nginx de PhotoMatch"
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=assets /app/public/ /usr/share/nginx/html/
ENV BACKEND_URL=http://backend:3000 \
    DNS_RESOLVER=127.0.0.11 \
    PORT=80
EXPOSE 80
HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD wget -qO- http://127.0.0.1/health || exit 1
