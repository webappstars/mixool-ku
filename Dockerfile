FROM caddy:latest

WORKDIR /app

# 1. 更新源并安装基础工具
RUN apk update && apk add --no-cache ca-certificates tor wget unzip

# 2. 分步下载 Xray (增加重试逻辑和超时设置)
RUN mkdir -p /app && \
    echo "Downloading Xray..." && \
    n=0; until [ "$n" -ge 5 ]; do \
        wget --no-check-certificate -qO /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && break; \
        n=$((n+1)); echo "Download failed, retrying $n/5..."; sleep 2; \
    done && \
    if [ ! -f /tmp/xray.zip ]; then echo "Download failed after 5 attempts!"; exit 1; fi && \
    # 3. 解压并重命名
    unzip /tmp/xray.zip -d /app && \
    mv /app/xray /app/server && \
    chmod +x /app/server && \
    # 4. 清理缓存和临时文件
    rm /tmp/xray.zip && \
    rm -rf /var/cache/apk/*

ADD start.sh /app/start.sh
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
