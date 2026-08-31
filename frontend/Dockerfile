# La app usa vistas renderizadas en servidor; esta etapa arma los assets estáticos.
FROM alpine:3.22 AS assets
WORKDIR /assets
COPY public/ ./

# Nginx sirve CSS y actúa como entrada única hacia el backend Express.
FROM nginx:1.29-alpine AS runtime
LABEL org.opencontainers.image.source="https://github.com/LautyUCC/ingesoft3"
LABEL org.opencontainers.image.description="Frontend Nginx de PhotoMatch"
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=assets /assets/ /usr/share/nginx/html/
EXPOSE 80
HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD wget -qO- http://127.0.0.1/health || exit 1
