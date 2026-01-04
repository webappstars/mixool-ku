#!/bin/sh

# ==========================================
# 1. 環境變數設置 (若系統未提供則使用默認值)
# ==========================================
export PORT=${PORT:-8080}
export AUUID=${AUUID:-8f91b6a0-e8ee-11ea-adc1-0242ac120002}
export ParameterSSENCYPT=${ParameterSSENCYPT:-chacha20-ietf-poly1305}
export CADDYIndexPage=${CADDYIndexPage:-https://raw.githubusercontent.com/caddyserver/dist/master/welcome/index.html}
export CONFIGCADDY=${CONFIGCADDY:-https://raw.githubusercontent.com/webappstars/mixool-ku/refs/heads/main/etc/Caddyfile}
export CONFIGSERVER=${CONFIGSERVER:-https://raw.githubusercontent.com/webappstars/mixool-ku/refs/heads/main/etc/server.jsonc}

# ==========================================
# 2. 配置路徑準備
# ==========================================
mkdir -p /etc/caddy/ /usr/share/caddy
echo -e "User-agent: *\nDisallow: /" > /usr/share/caddy/robots.txt

# 3. 下載偽裝網頁
wget $CADDYIndexPage -O /usr/share/caddy/index.html
if [ -f /usr/share/caddy/index.html ]; then
    unzip -qo /usr/share/caddy/index.html -d /usr/share/caddy/ 2>/dev/null \
    && mv /usr/share/caddy/*/* /usr/share/caddy/ 2>/dev/null || true
fi

# 4. 處理配置
# 渲染 Caddyfile（包含基礎認證哈希）
wget -qO- $CONFIGCADDY | sed -e "1c :$PORT" \
    -e "s/\$AUUID/$AUUID/g" \
    -e "s/\$MYUUID-HASH/$(caddy hash-password --plaintext $AUUID)/g" > /etc/caddy/Caddyfile

# 渲染 Server 配置並保存為 server.jsonc
wget -qO- $CONFIGSERVER | sed -e "s/\$AUUID/$AUUID/g" \
    -e "s/\$ParameterSSENCYPT/$ParameterSSENCYPT/g" > /app/server.jsonc

# 5. 啟動服務
tor &

# 使用 server 名字啟動核心程序
/app/server -config /app/server.jsonc &

# 啟動 Caddy (守護進程)
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
