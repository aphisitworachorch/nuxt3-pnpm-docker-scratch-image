ARG NODE_VERSION="lts"

# change with the Linux Alpine version of your choice
ARG ALPINE_VERSION="3.20"

# Use a large Node.js base image to build the application and name it "build"
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} as build

COPY . /app

WORKDIR /app

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

RUN apk update && \
    apk add --update git && \
    apk add --update openssh && \
    apk add --no-cache python3 py3-pip

RUN --mount=type=cache,id=pnpm,target=/pnpm/store pnpm install
RUN pnpm run build

# Exact same steps as before
COPY . .

# Create a new Docker image and name it "prod"
FROM scratch

# Copy the built application from the "build" image into the "prod" image
# This will only copy whatever is in the .output folder and ignore useless files like node_modules!
COPY --from=build /usr/local/bin/node /usr/local/bin/node
COPY --from=build "/usr/lib/libstdc++.so.6" "/usr/lib/libstdc++.so.6"
COPY --from=build /usr/lib/libgcc_s.so.1 /usr/lib/libgcc_s.so.1
COPY --from=build /usr/lib/libbrotlicommon.so.1 /usr/lib/libbrotlicommon.so.1
COPY --from=build /usr/lib/libbrotlidec.so.1 /usr/lib/libbrotlidec.so.1
COPY --from=build /usr/lib/libbrotlienc.so.1 /usr/lib/libbrotlienc.so.1
COPY --from=build /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY --from=build /app/.output /app

WORKDIR /app

ENV NUXT_HOST=0.0.0.0
ENV NUXT_PORT=3000

EXPOSE 3000

# Start is the same as before
CMD ["node", "server/index.mjs"]
