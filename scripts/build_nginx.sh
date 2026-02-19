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

ln -sf /usr/local/include/openssl /usr/include/openssl
cp -P /usr/local/lib/libssl.so* /usr/lib/
cp -P /usr/local/lib/libcrypto.so* /usr/lib/

export C_INCLUDE_PATH="/usr/local/include:/usr/include"
export LIBRARY_PATH="/usr/local/lib:/usr/lib"
export LD_LIBRARY_PATH="/usr/local/lib:/usr/lib"

echo ">>> Verifying OpenSSL FIPS Installation..."
openssl version
ls -l /usr/local/include/openssl/ssl.h

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
    "--with-cc-opt='-I/usr/local/include -O3 -fstack-protector-strong -Wno-error'"
    "--with-ld-opt='-L/usr/local/lib -Wl,-rpath,/usr/local/lib -lssl -lcrypto -ldl -lpthread'"
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
            wget -L -qO /tmp/mod_archive "${url}"
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
make DESTDIR="${FINAL_ROOTFS}" install

strip --strip-all "${FINAL_ROOTFS}/usr/sbin/nginx"
find "${FINAL_ROOTFS}/usr/lib/nginx/modules" -name "*.so" -exec strip --strip-all {} + 2>/dev/null || true

{
    echo "# Auto-generated Dynamic Modules Loader"
    for so in $(ls "${FINAL_ROOTFS}/usr/lib/nginx/modules"/*.so 2>/dev/null); do
        echo "load_module /usr/lib/nginx/modules/$(basename "$so");"
    done
} > "${FINAL_ROOTFS}/etc/nginx/modules.conf"