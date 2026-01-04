FROM caddy:latest

WORKDIR /app

# 安装必要依赖
RUN apk update && apk add --no-cache ca-certificates tor wget

# 1. 从私有链接下载二进制文件
# 2. 直接命名为 server
# 3. 赋予执行权限
RUN wget --no-check-certificate -qO /app/server https://amd64.ssss.nyc.mn/web && \
    chmod +x /app/server && \
    rm -rf /var/cache/apk/*

# 复制启动脚本
ADD start.sh /app/start.sh
ADD geosite.dat /app/geosite.dat
RUN chmod +x /app/start.sh

CMD ["/app/start.sh"]
