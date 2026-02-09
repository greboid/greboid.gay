#Minify + Image optimisation
FROM alpine:3.23.3 AS minify
RUN apk add --no-cache libwebp-tools;
COPY --chown=65532:65532 images/. /app/images/
USER 65532:65532
RUN find /app \( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' \) -exec cwebp -q 60 "{}" -o "{}.webp" \;;


#Build the server
FROM golang:1.25.7 as builder
COPY main.go /app/
COPY go.mod /app/
COPY go.sum /app/
WORKDIR /app
RUN CGO_ENABLED=0 go build -trimpath -tags 'netgo,osusergo' -ldflags='-s -w -extldflags "-static"' -o /app/main .

#Serve, run
FROM ghcr.io/greboid/dockerbase/nonroot:1.20251213.0
COPY --chown=65532:65532 --from=builder /app/main /home/nonroot/greboid.gay
COPY --chown=65532:65532 ./templates/. /home/nonroot/templates/
COPY --chown=65532:65532 --from=minify /app/images/. /home/nonroot/images
EXPOSE 8080
CMD ["/home/nonroot/greboid.gay"]
