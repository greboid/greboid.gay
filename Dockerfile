FROM registry.greboid.com/mirror/debian:latest as webp
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends webp python && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY images/. /app
COPY minify.sh /app
RUN /bin/bash /app/minify.sh
RUN ls /app
RUN ls /app/images

FROM registry.greboid.com/mirror/golang:latest as builder
WORKDIR /app
COPY main.go /app
COPY go.mod /app
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o main .

FROM scratch
WORKDIR /app
COPY --from=builder /app/main /app
COPY ./templates/. /app/templates/
COPY --from=webp /app/images/. /app/images
EXPOSE 8080
CMD ["/app/main"]