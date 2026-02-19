#!/usr/bin/env bash
set -e

NGINX_VERSION=$1
MODULES_JSON=$2
ENABLED_MODULES=$3

NGINX_SRC="/src/nginx-${NGINX_VERSION}"
FINAL_ROOTFS="/rootfs"
MOD_SRC_DIR="/src/modules_src"

mkdir -p "${MOD_SRC_DIR}" "${FINAL_ROOTFS}/usr/lib/nginx/modules" "${FINAL_ROOTFS}/etc/nginx"

if [ ! -d "${NGINX_SRC}" ]; then
    wget -L -qO- "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" | tar xz -C /src
fi

sed -i 's/-Werror//g' "${NGINX_SRC}/auto/cc/gcc"

CONFIGURE_FLAGS=(
    "--prefix=/etc/nginx"
    "--sbin-path=/usr/sbin/nginx"
    "--modules-path=/usr/lib/nginx/modules"
    "--conf-path=/etc/nginx/nginx.conf"
    "--error-log-path=/var/log/nginx/error.log"
    "--http-log-path=/var/log/nginx/access.log"
    "--pid-path=/var/run/nginx.pid"
    "--lock-path=/var/run/nginx.lock"
    "--user=nginx"
    "--group=nginx"
    "--with-threads"
    "--with-file-aio"
    "--with-http_ssl_module"
    "--with-http_v2_module"
    "--with-http_v3_module"
    "--with-http_realip_module"
    "--with-http_stub_status_module"
    "--with-http_auth_request_module"
    "--with-stream"
    "--with-stream_ssl_module"
    "--with-stream_ssl_preread_module"
    "--with-cc-opt=-I/usr/local/include -O3 -fstack-protector-strong -Wno-error -Wno-unterminated-string-initialization -D_FORTIFY_SOURCE=2"
    "--with-ld-opt=-L/usr/local/lib -Wl,-rpath,/usr/local/lib -lssl -lcrypto -ldl -lpthread"
)

for mod_name in $(echo "${ENABLED_MODULES}" | jq -r '.[]'); do
    mod_info=$(echo "${MODULES_JSON}" | jq -c ".\"${mod_name}\"")
    type=$(echo "${mod_info}" | jq -r '.type')
    flag=$(echo "${mod_info}" | jq -r '.flag')

    if [[ "$type" == "ext" ]]; then
        url=$(echo "${mod_info}" | jq -r '.url')
        dest="${MOD_SRC_DIR}/${mod_name}"
        
        if [ ! -d "${dest}" ]; then
            mkdir -p "${dest}"
            wget -L -qO /tmp/mod.tar.gz "${url}"
            tar -xzf /tmp/mod.tar.gz -C "${dest}" --strip-components=1
            rm /tmp/mod.tar.gz
        fi
        actual_flag=$(echo "${flag}" | sed "s|{{DIR}}|${dest}|g")
        CONFIGURE_FLAGS+=("${actual_flag}")
    else
        CONFIGURE_FLAGS+=("${flag}")
    fi
done

cd "${NGINX_SRC}"
./configure "${CONFIGURE_FLAGS[@]}"
make -j$(nproc)
make DESTDIR="${FINAL_ROOTFS}" install

strip --strip-all "${FINAL_ROOTFS}/usr/sbin/nginx"
if [ -d "${FINAL_ROOTFS}/usr/lib/nginx/modules" ]; then
    find "${FINAL_ROOTFS}/usr/lib/nginx/modules" -name "*.so" -exec strip --strip-all {} +
fi

{
    echo "# Auto-generated Dynamic Modules Loader"
    if [ -d "${FINAL_ROOTFS}/usr/lib/nginx/modules" ]; then
        for so in "${FINAL_ROOTFS}/usr/lib/nginx/modules"/*.so; do
            [[ -e "$so" ]] || continue
            echo "load_module /usr/lib/nginx/modules/$(basename "$so");"
        done
    fi
} > "${FINAL_ROOTFS}/etc/nginx/modules.conf"