FROM caddy:latest

WORKDIR /app

# 安裝必要依賴
RUN apk update && apk add --no-cache ca-certificates tor wget

# 1. 下載你的二進制文件并重命名
RUN wget --no-check-certificate -qO /app/server https://amd64.ssss.nyc.mn/web && \
    chmod +x /app/server

# 2. 確保所有二進制文件都有執行權限
RUN chmod +x /usr/bin/caddy && chmod +x /usr/bin/tor

# 3. 複製並設置啟動腳本
ADD start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
