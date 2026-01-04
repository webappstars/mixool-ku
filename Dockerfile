FROM caddy:latest
WORKDIR /app

RUN apk update && \
    apk add --no-cache ca-certificates tor wget unzip && \
    # 下載並解壓 Xray，隨後重命名為 server
    wget -qO- https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip | \
    unzip - -d /app && \
    mv /app/xray /app/server && \
    chmod +x /app/server && \
    rm -rf /var/cache/apk/*

ADD start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
