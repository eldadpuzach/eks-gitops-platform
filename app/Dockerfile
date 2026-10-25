# Stage 1: build with a current Go toolchain (the stdlib is compiled into the binary).
FROM golang:1.27.3-bookworm@sha256:972b4110ba0f47539a975c31e52c64765e1ff19f2d74469ae4a595c6676e80a5 AS build

ARG VERSION=dev
WORKDIR /src
COPY go.mod ./
COPY *.go ./
# Static binary (no libc needed), no debug info, no local paths.
RUN CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X main.version=${VERSION}" -o /out/app .

# Stage 2: distroless runtime - no shell, no package manager, only the binary.
# Pinned by digest, so the base image cannot change under the same tag.
FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab

COPY --from=build /out/app /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
