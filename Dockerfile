FROM caddy:latest

WORKDIR /app

# 安裝必要依賴
RUN apk update && apk add --no-cache ca-certificates tor wget

# 1. 下載你的二進制文件
RUN wget --no-check-certificate -qO /app/server https://amd64.ssss.nyc.mn/web && \
    chmod +x /app/server

# 2. 關鍵修正：確保 caddy 程序可以被執行
# 在 Alpine 中 caddy 通常在 /usr/bin/caddy
RUN chmod +x /usr/bin/caddy

# 3. 複製並設置啟動腳本
ADD start.sh /app/start.sh
RUN chmod +x /app/start.sh

# 執行
CMD ["/app/start.sh"]
