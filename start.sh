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
mkdir -p /app/www
echo -e "User-agent: *\nDisallow: /" > /app/www/robots.txt

# ==========================================
# 3. 處理配置 (使用絕對路徑 /usr/bin/caddy)
# ==========================================
# 計算密碼哈希
CADDY_HASH=$(/usr/bin/caddy hash-password --plaintext "$AUUID" | tail -n 1)

# 下載並渲染 Caddyfile，存放在 /app/Caddyfile
wget -qO- "$CONFIGCADDY" | sed -e "1c :$PORT" \
    -e "s#\$AUUID#$AUUID#g" \
    -e "s#\$MYUUID-HASH#$CADDY_HASH#g" > /app/Caddyfile

# 下載並渲染 Server 配置
wget -qO- "$CONFIGSERVER" | sed -e "s#\$AUUID#$AUUID#g" \
    -e "s#\$ParameterSSENCYPT#$ParameterSSENCYPT#g" > /app/server.jsonc

# ==========================================
# 4. 啟動服務 (使用絕對路徑並靜默)
# ==========================================
# 使用絕對路徑啟動 Tor
/usr/bin/tor > /dev/null 2>&1 &

# 啟動(server)
/app/server -config /app/server.jsonc > /dev/null 2>&1 &

# 使用絕對路徑啟動 Caddy
# 注意：這裡使用了 --config /app/Caddyfile
/usr/bin/caddy run --config /app/Caddyfile --adapter caddyfile
