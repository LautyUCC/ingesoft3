# Etapa de dependencias completas: se usa para ejecutar pruebas.
FROM node:22-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci

# Etapa de pruebas, invocable con: docker build --target test .
FROM dependencies AS test
COPY src ./src
COPY test ./test
RUN npm test

# Dependencias de producción: excluye supertest y herramientas de desarrollo.
FROM node:22-alpine AS production-dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Imagen final: solo runtime, dependencias productivas y código ejecutable.
FROM node:22-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
LABEL org.opencontainers.image.source="https://github.com/LautyUCC/ingesoft3"
LABEL org.opencontainers.image.description="Backend Node.js de PhotoMatch"
COPY --from=production-dependencies /app/node_modules ./node_modules
COPY package*.json ./
COPY src ./src
EXPOSE 3000
USER node
CMD ["node", "src/app.js"]
