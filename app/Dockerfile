# v1 - DELIBERATELY VULNERABLE, to see the Trivy gate fail.
# An old, full Go image is used as the runtime: a whole Debian OS,
# compilers and an old Go toolchain ship to production.
FROM golang:1.22

ARG VERSION=dev
WORKDIR /src
COPY go.mod main.go ./
RUN go build -ldflags "-X main.version=${VERSION}" -o /app .

EXPOSE 8080
CMD ["/app"]
