FROM golang:1.25 AS builder

WORKDIR /src
COPY go.mod ./
COPY main.go ./
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/q-demo .

FROM alpine:3.20
WORKDIR /app
COPY --from=builder /out/q-demo /app/q-demo
ENV APP_VERSION=dev
EXPOSE 8080
ENTRYPOINT ["/app/q-demo"]
