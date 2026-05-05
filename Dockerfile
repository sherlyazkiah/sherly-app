# --- TAHAP 1: Install Dependencies ---
FROM node:25-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

# --- TAHAP 2: Build Aplikasi ---
FROM node:25-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Matikan pengumpulan data anonim Next.js saat build
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# --- TAHAP 3: Runner (Production) ---
FROM node:25-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Buat user khusus (keamanan) agar tidak menggunakan root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Salin file hasil build yang diperlukan saja
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

ENV PORT=3000
ENV HOSTNAME=0.0.0.0

CMD ["node", "server.js"]