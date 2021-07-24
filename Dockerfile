FROM registry.greboid.com/mirror/debian:latest as webp
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends webp python && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY images/. /app
COPY minify.sh /app
RUN /bin/bash /app/minify.sh

FROM registry.greboid.com/mirror/golang:latest as builder

ENV USER=appuser
ENV UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

WORKDIR /app
COPY main.go /app
COPY go.mod /app
COPY go.sum /app
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o main .

FROM scratch
WORKDIR /

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /etc/group /etc/group
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

COPY --from=builder /app/main /gay-site
COPY ./templates/. /templates/
COPY --from=webp /app/images/. /images

EXPOSE 8080
USER appuser:appuser
CMD ["/gay-site"]
