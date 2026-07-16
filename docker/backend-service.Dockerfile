# 中文注释：同一个 Dockerfile 通过 APP 参数分别构建 HTTP 与 MQTT 服务镜像。
FROM golang:1.25-alpine AS builder

ARG APP=http
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . ./
RUN if [ "$APP" = "http" ]; then \
      CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags "-s -w" -o /out/seacontroll-http ./http/cmd; \
    elif [ "$APP" = "mqtt" ]; then \
      CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags "-s -w" -o /out/seacontroll-mqtt ./mqtt/cmd; \
    else \
      echo "unknown APP=$APP" >&2; exit 1; \
    fi

FROM alpine:3.20

ARG APP=http
RUN adduser -D -H -s /sbin/nologin appuser && apk add --no-cache ca-certificates tzdata
WORKDIR /app

COPY --from=builder /out/seacontroll-${APP} /app/seacontroll
USER appuser

EXPOSE 8080 8082 1883
ENTRYPOINT ["/app/seacontroll"]
