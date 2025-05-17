FROM oven/bun:alpine as build

COPY . /app

WORKDIR /app

RUN mkdir -p /prod

COPY package.json bun.lock /prod/

RUN cd /prod && bun install --frozen-lockfile

FROM build AS prerelease
COPY --from=build /prod/node_modules node_modules
COPY . .

ENV NODE_ENV=production

RUN bun run build

# Create a new Docker image and name it "prod"
FROM scratch

# Copy the built application from the "build" image into the "prod" image
# This will only copy whatever is in the .output folder and ignore useless files like node_modules!

WORKDIR /app

COPY --from=prerelease /usr/local/bin/bun /usr/local/bin/bun
COPY --from=prerelease "/usr/lib/libstdc++.so.6" "/usr/lib/libstdc++.so.6"
COPY --from=prerelease /usr/lib/libgcc_s.so.1 /usr/lib/libgcc_s.so.1
# Can change this ld-musl-x86_64.so.1 to ld-musl-aarch64.so.1 for ARM-based Architecture
COPY --from=prerelease /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1 
COPY --from=prerelease /app/.output /app


ENV NUXT_HOST=0.0.0.0
ENV NUXT_PORT=3000

EXPOSE 3000

# Start is the same as before
CMD ["bun", "run","server/index.mjs"]
