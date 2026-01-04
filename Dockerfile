FROM caddy:latest
WORKDIR /app
RUN apk update && apk add --no-cache ca-certificates tor wget unzip && \
    wget -qO- https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip | unzip - -d /app && \
    chmod +x /app/xray && rm -rf /var/cache/apk/*
ADD start.sh /app/start.sh
RUN chmod +x /app/start.sh
CMD ["/app/start.sh"]
