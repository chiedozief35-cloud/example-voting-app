FROM node@sha256:c3de60bf2f9dd0ac6370e6117950ff62d6e339527e7472301c9c78a017978392

ENV NODE_ENV=production     PORT=8080

RUN apt-get update &&     apt-get install -y --no-install-recommends curl tini &&     rm -rf /var/lib/apt/lists/*

WORKDIR /usr/local/app

COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY . .

USER node

EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]
