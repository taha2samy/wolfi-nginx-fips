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
    echo ">>> Downloading Nginx..."
    curl -L "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" | tar xz -C /src
fi

if [ ! -f "/usr/local/include/openssl/ssl.h" ]; then
    echo ">>> OpenSSL Headers missing. Injecting from source..."
    curl -L "https://github.com/openssl/openssl/archive/refs/tags/openssl-3.1.2.tar.gz" -o /tmp/ssl.tar.gz
    mkdir -p /tmp/ssl-src
    tar -xzf /tmp/ssl.tar.gz -C /tmp/ssl-src --strip-components=1
    mkdir -p /usr/local/include/openssl
    cp -rf /tmp/ssl-src/include/openssl/* /usr/local/include/openssl/
    rm -rf /tmp/ssl*
fi

ln -sf /usr/local/lib/libssl.so.3 /usr/local/lib/libssl.so || true
ln -sf /usr/local/lib/libcrypto.so.3 /usr/local/lib/libcrypto.so || true
ln -sf /usr/local/lib/libssl.so /usr/lib/libssl.so || true
ln -sf /usr/local/lib/libcrypto.so /usr/lib/libcrypto.so || true

sed -i 's/-Werror//g' "${NGINX_SRC}/auto/cc/gcc"

export CPATH="/usr/local/include"
export LIBRARY_PATH="/usr/local/lib"
export LD_LIBRARY_PATH="/usr/local/lib"

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
    "--with-cc-opt=-I/usr/local/include -O3 -fstack-protector-strong -Wno-error"
    "--with-ld-opt=-L/usr/local/lib -Wl,-rpath,/usr/local/lib -lssl -lcrypto -ldl -lpthread -lz"
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
            curl -L "$url" -o /tmp/mod_archive
            MAGIC=$(head -c 4 /tmp/mod_archive | cat -v)
            if [[ "$MAGIC" == "PK^C^D" ]]; then
                unzip -q /tmp/mod_archive -d /tmp/unpacked
                mv /tmp/unpacked/*/* "${dest}/" || mv /tmp/unpacked/* "${dest}/" || true
                rm -rf /tmp/unpacked
            else
                tar -xzf /tmp/mod_archive -C "${dest}" --strip-components=1
            fi
            rm /tmp/mod_archive
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
make install DESTDIR="${FINAL_ROOTFS}"

strip --strip-all "${FINAL_ROOTFS}/usr/sbin/nginx"
if [ -d "${FINAL_ROOTFS}/usr/lib/nginx/modules" ]; then
    find "${FINAL_ROOTFS}/usr/lib/nginx/modules" -name "*.so" -exec strip --strip-all {} + 2>/dev/null || true
fi

{
    echo "# Auto-generated Dynamic Modules Loader"
    if [ -d "${FINAL_ROOTFS}/usr/lib/nginx/modules" ]; then
        for so in $(ls "${FINAL_ROOTFS}/usr/lib/nginx/modules"/*.so 2>/dev/null); do
            echo "load_module /usr/lib/nginx/modules/$(basename "$so");"
        done
    fi
} > "${FINAL_ROOTFS}/etc/nginx/modules.conf"