#!/bin/sh

# 1. 配置路径准备 
mkdir -p /etc/caddy/ /usr/share/caddy
echo -e "User-agent: *\nDisallow: /" > /usr/share/caddy/robots.txt

# 2. 下载伪装网页 
wget $CADDYIndexPage -O /usr/share/caddy/index.html
if [ -f /usr/share/caddy/index.html ]; then
    unzip -qo /usr/share/caddy/index.html -d /usr/share/caddy/ 2>/dev/null \
    && mv /usr/share/caddy/*/* /usr/share/caddy/ 2>/dev/null || true
fi

# 3. 处理 Caddyfile 和 Xray 配置 
# 这里的 caddy hash-password 会在新的路径下正常执行 
wget -qO- $CONFIGCADDY | sed -e "1c :$PORT" \
    -e "s/\$AUUID/$AUUID/g" \
    -e "s/\$MYUUID-HASH/$(caddy hash-password --plaintext $AUUID)/g" > /etc/caddy/Caddyfile

# 【修改点】将配置保存为 /app/server.jsonc
wget -qO- $CONFIGXRAY | sed -e "s/\$AUUID/$AUUID/g" \
    -e "s/\$ParameterSSENCYPT/$ParameterSSENCYPT/g" > /app/server.jsonc

# 4. StoreFiles 逻辑 
mkdir -p /usr/share/caddy/$AUUID && wget -O /usr/share/caddy/$AUUID/StoreFiles $StoreFiles
wget -P /usr/share/caddy/$AUUID -i /usr/share/caddy/$AUUID/StoreFiles

for file in $(ls /usr/share/caddy/$AUUID); do
    [[ "$file" != "StoreFiles" ]] && echo "<a href=\"$file\" download>$file</a><br>" >> /usr/share/caddy/$AUUID/ClickToDownloadStoreFiles.html
done

# 5. 启动服务 
tor &

# 【修改点】从 /app 目录启动 Xray，读取 server.jsonc
/app/xray -config /app/server.jsonc &

# 启动 Caddy 
caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
