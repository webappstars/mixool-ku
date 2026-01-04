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

# 自動獲取 Caddy 二進制路徑
CADDY_BIN=$(command -v caddy)

# ==========================================
# 2. 配置路徑準備 (避開系統保護目錄)
# ==========================================
mkdir -p /app/www
rm -rf /app/www/*

# ==========================================
# 3. 下載並處理偽裝網頁
# ==========================================
wget -q "$CADDYIndexPage" -O /app/www/index.html

# 如果下載的是 ZIP 壓縮包，則自動解壓並歸位
if file /app/www/index.html | grep -q 'Zip archive'; then
    unzip -qo /app/www/index.html -d /app/www/tmp_web
    # 尋找 index.html 所在目錄並將其內容提升至 /app/www
    INDEX_DIR=$(find /app/www/tmp_web -name "index.html" -exec dirname {} \; | head -n 1)
    if [ -n "$INDEX_DIR" ]; then
        mv "$INDEX_DIR"/* /app/www/
    fi
    rm -rf /app/www/tmp_web /app/www/index.html
fi

# 兜底：如果沒有 index.html，生成一個簡單頁面防止顯示文件列表
if [ ! -f /app/www/index.html ]; then
    echo "<html><head><title>Loading</title></head><body><h1>System Running</h1></body></html>" > /app/www/index.html
fi

echo -e "User-agent: *\nDisallow: /" > /app/www/robots.txt

# ==========================================
# 4. 處理配置文件 (修正 sed 分隔符與絕對路徑)
# ==========================================
# 計算 Caddy 哈希
CADDY_HASH=$($CADDY_BIN hash-password --plaintext "$AUUID" | tail -n 1)

# 下載並渲染 Caddyfile (改用 # 作為分隔符)
wget -qO- "$CONFIGCADDY" | sed -e "1c :$PORT" \
    -e "s#\$AUUID#$AUUID#g" \
    -e "s#\$MYUUID-HASH#$CADDY_HASH#g" > /app/Caddyfile

# 下載並渲染 Server (Xray) 配置
wget -qO- "$CONFIGSERVER" | sed -e "s#\$AUUID#$AUUID#g" \
    -e "s#\$ParameterSSENCYPT#$ParameterSSENCYPT#g" > /app/server.jsonc

# ==========================================
# 5. 啟動服務 (靜默啟動後台進程)
# ==========================================
# 啟動 Tor
/usr/bin/tor > /dev/null 2>&1 &

# 啟動核心服務 (Xray)
/app/server -config /app/server.jsonc > /dev/null 2>&1 &

# 啟動 Caddy (前台運行)
$CADDY_BIN run --config /app/Caddyfile --adapter caddyfile
