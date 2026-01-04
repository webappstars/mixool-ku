#!/bin/sh

# 1. 配置路徑準備
mkdir -p /etc/caddy/ /usr/share/caddy
echo -e "User-agent: *\nDisallow: /" > /usr/share/caddy/robots.txt

# 2. 下載偽裝網頁
wget $CADDYIndexPage -O /usr/share/caddy/index.html
if [ -f /usr/share/caddy/index.html ]; then
    unzip -qo /usr/share/caddy/index.html -d /usr/share/caddy/ 2>/dev/null \
    && mv /usr/share/caddy/*/* /usr/share/caddy/ 2>/dev/null || true
fi

# 3. 處理 Caddyfile 和 Xray 配置
# 替換 Caddyfile 中的變量
wget -qO- $CONFIGCADDY | sed -e "1c :$PORT" \
    -e "s/\$AUUID/$AUUID/g" \
    -e "s/\$MYUUID-HASH/$(caddy hash-password --plaintext $AUUID)/g" > /etc/caddy/Caddyfile

# 替換 Xray 配置變量並保存為 server.jsonc
wget -qO- $CONFIGXRAY | sed -e "s/\$AUUID/$AUUID/g" \
    -e "s/\$ParameterSSENCYPT/$ParameterSSENCYPT/g" > /app/server.jsonc

# 4. 啟動服務
tor &

# 【修改點】使用新名字 server 啟動，讀取 server.jsonc 配置
/app/server -config /app/server.jsonc &

# 啟動 Caddy
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
