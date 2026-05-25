# Fumadocs — site de documentação (Next.js) que renderiza a pasta docs/ do projeto.
# A pasta docs/ é montada como volume em runtime (ver docker-compose.sdd.yml),
# então mudar a doc não exige rebuild — só recarregar.
FROM node:24-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install

FROM node:24-alpine AS runner
WORKDIR /app
ENV NODE_ENV=development
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
# Modo dev: pega alterações da doc montada em volume sem rebuild.
CMD ["npm", "run", "dev", "--", "-p", "3000", "-H", "0.0.0.0"]
