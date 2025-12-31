#Minify + Image optimisation
FROM alpine:3.23.2 AS minify
RUN apk add --no-cache libwebp-tools;
COPY --chown=65532:65532 images/. /app/images/
USER 65532:65532
RUN find /app \( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' \) -exec cwebp -q 60 "{}" -o "{}.webp" \;;


#Build the server
FROM golang:1.25.5 as builder
COPY main.go /app/
COPY go.mod /app/
COPY go.sum /app/
WORKDIR /app
RUN CGO_ENABLED=0 go build -trimpath -tags 'netgo,osusergo' -ldflags='-s -w -extldflags "-static"' -o /app/main .

#Serve, run
FROM ghcr.io/greboid/dockerbase/nonroot:1.20251213.0
COPY --from=builder /app/main /greboid.gay
COPY ./templates/. /templates/
COPY --from=minify /app/images/. /images
EXPOSE 8080
CMD ["/greboid.gay"]
