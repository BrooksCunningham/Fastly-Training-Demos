#!/bin/bash

# Set the URL of the tar.gz file
url="https://dl.signalsciences.net/sigsci-module-nginx/sigsci-module-nginx_latest.tar.gz"

# Make extraction dir
destination="/opt/sigsci"
mkdir -p "$destination"

# Download, extract, cleanup
if command -v curl &> /dev/null; then
    break
else
    echo "installing curl"
    apk add curl
fi

echo "Downloading, and extracting module"
curl -L "$url" -o "$destination/sigsci-module-nginx.tar.gz"
tar -xzvf "$destination/sigsci-module-nginx.tar.gz" -C "$destination"
mv $destination/sigsci-module-nginx $destination/nginx

echo "Removing module"
rm "$destination/sigsci-module-nginx.tar.gz"

if test -f $destination/sigsci-module-nginx.tar.gz; then
  echo "file was not cleaned up"
fi

# Install nginx
if command -v nginx &> /dev/null; then
    action="found"
else
    echo "nginx could not be found, installing"
    apk add nginx
    action="installed"
fi

nginx_version=$(nginx -v 2>&1 | awk -F/ '{print $2}' | cut -d' ' -f1)
echo "nginx $action: $nginx_version"

echo "installing openresty lua module"
apk add nginx-mod-http-lua

echo "adding module to config..."
symlink_exists() { [ -e "$1" ] && [ -L "$1" ]; }
if ! symlink_exists "/etc/nginx/http.d/sigsci.conf"; then
    ln -s "/opt/sigsci/nginx/sigsci.conf" "/etc/nginx/http.d/sigsci.conf"
fi

cat <<'EOF' >/opt/sigsci/nginx/sigsci_check_lua.conf
load_module modules/ndk_http_module.so;
load_module modules/ngx_http_lua_module.so;

events {
   worker_connections 768;
   # multi_accept on;
}

http {
init_by_lua '
local m = {}
local ngx_lua_version = "dev"

if ngx then
-- if not in testing environment
ngx_lua_version = tostring(ngx.config.ngx_lua_version)
ngx.log(ngx.STDERR, "INFO:", " Check for jit: lua version: ", ngx_lua_version)
end

local r, jit = pcall(require, "jit")
if not r then
error("ERROR: No lua jit support: No support for NGWAF Lua module")
else

if jit then
   m._SERVER_FLAVOR = ngx_lua_version .. ", lua=" .. jit.version
   if os.getenv("SIGSCI_NGINX_DISABLE_JIT") == "true" then
      nginx.log(ngx.STDERR, "WARNING:", "Disabling lua jit because env var: SIGSCI_NGINX_DISABLE_JIT=", "true")
   end
   ngx.log(ngx.STDERR, "INFO:", " Bravo! You have lua jit support=", m._SERVER_FLAVOR)
else
   error("ERROR: No luajit support: No support for NGWAF module")
end
end
';
}
EOF

# Check if we can reload config.
if nginx -t -c /opt/sigsci/nginx/sigsci_check_lua.conf 2>&1 | grep -q "is successful"; then
    echo "Configuration test is successful."
else
    echo "Configuration test failed."
fi

echo "Installation completed successfully."