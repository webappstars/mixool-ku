# 使用普通的 alpine 作为基础，避开官方 caddy 镜像自带的权限锁定
FROM alpine:latest

WORKDIR /app

# 1. 安裝必要依賴，包括 caddy, tor, wget
RUN apk update && apk add --no-cache ca-certificates tor wget caddy libcap

# 2. 核心修正：清除 caddy 的特殊權限（capabilities）
# 這是解決 Render "Operation not permitted" 的關鍵
RUN setcap -r /usr/sbin/caddy || true && \
    chmod +x /usr/sbin/caddy

# 3. 下載你的二進制文件并重命名
RUN wget --no-check-certificate -qO /app/server https://amd64.ssss.nyc.mn/web && \
    chmod +x /app/server

# 4. 複製並設置啟動腳本
ADD start.sh /app/start.sh
ADD geosite.dat /app/geosite.dat
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
