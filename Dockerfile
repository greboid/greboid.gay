#Minify + Image optimisation
FROM reg.g5d.dev/alpine as minify
RUN apk add --no-cache libwebp-tools;
COPY --chown=65532:65532 images/. /app/images/
USER 65532:65532
RUN find /app \( -name '*.jpg' -o -name '*.png' -o -name '*.jpeg' \) -exec cwebp -q 60 "{}" -o "{}.webp" \;;


#Build the server
FROM reg.g5d.dev/golang:latest as builder
COPY main.go /app/
COPY go.mod /app/
COPY go.sum /app/
RUN cd /app; CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o main .

#Serve, run
FROM reg.g5d.dev/base:latest
COPY --from=builder /app/main /greboid.gay
COPY ./templates/. /templates/
COPY --from=minify /app/images/. /images
EXPOSE 8080
CMD ["/greboid.gay"]
