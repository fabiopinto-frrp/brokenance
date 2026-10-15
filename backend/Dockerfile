FROM node:24-slim

WORKDIR /app

# Prisma's schema engine (used by `prisma migrate deploy`) needs OpenSSL.
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends openssl \
  && rm -rf /var/lib/apt/lists/*

# Install everything, including the Prisma CLI, which is needed to run migrations on start.
COPY package.json package-lock.json ./
RUN npm ci

COPY prisma ./prisma
COPY prisma.config.js ./
# prisma.config.js loads .env through this file (there is no .env in the image, which is fine).
COPY src/config/load-env.js ./src/config/
RUN npx prisma generate

COPY src ./src
COPY scripts ./scripts

ENV NODE_ENV=production
USER node
EXPOSE 3000

# Apply pending migrations, then start the API.
CMD ["sh", "-c", "npx prisma migrate deploy && node src/server.js"]
