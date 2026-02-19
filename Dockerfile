# syntax=docker/dockerfile:1

ARG NGINX_VERSION=1.27.3
ARG FIPS_IMAGE=ghcr.io/taha2samy/wolfi-openssl-fips:3.5.5
ARG FIPS_IMAGE_DISTROLESS=ghcr.io/taha2samy/wolfi-openssl-fips:3.5.5-distroless

FROM cgr.dev/chainguard/wolfi-base:latest AS builder
ARG NGINX_VERSION
ARG MODULES_JSON
ARG ENABLED_MODULES

RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
    build-base pkgconf wget openssl-dev pcre-dev zlib-dev linux-headers \
    coreutils gd-dev libxml2-dev libxslt-dev geoip-dev libmaxminddb-dev \
    binutils scanelf posix-libc-utils bash tzdata ca-certificates perl perl-dev


COPY --from=ghcr.io/taha2samy/wolfi-openssl-fips:3.5.5 /usr/local /usr/local
ENV LD_LIBRARY_PATH="/usr/local/lib"

WORKDIR /src
COPY scripts/build_nginx.sh /usr/bin/build_nginx.sh
COPY scripts/extract_libs.sh /usr/bin/extract_libs.sh
RUN chmod +x /usr/bin/build_nginx.sh /usr/bin/extract_libs.sh

RUN --mount=type=cache,target=/root/.ccache \
    /usr/bin/build_nginx.sh "${NGINX_VERSION}" '${MODULES_JSON}' '${ENABLED_MODULES}'

RUN mkdir -p /rootfs/etc/nginx /rootfs/usr/sbin /rootfs/usr/lib/nginx/modules \
    /rootfs/var/log/nginx /rootfs/var/cache/nginx /rootfs/var/run /rootfs/tmp \
    /rootfs/var/lib/nginx && \
    cp /usr/sbin/nginx /rootfs/usr/sbin/ && \
    [ -d /usr/lib/nginx/modules ] && cp -r /usr/lib/nginx/modules/* /rootfs/usr/lib/nginx/modules/ || true && \
    cp -r /etc/nginx/* /rootfs/etc/nginx/ && \
    echo 'hosts: files dns' > /rootfs/etc/nsswitch.conf && \
    echo 'nginx:x:101:101:nginx:/var/cache/nginx:/sbin/nologin' > /rootfs/etc/passwd && \
    echo 'nginx:x:101:' > /rootfs/etc/group

RUN /usr/bin/extract_libs.sh /rootfs/usr/sbin/nginx /rootfs/usr/lib/nginx/modules/*.so

FROM ${FIPS_IMAGE_DISTROLESS} AS distroless
ARG NGINX_VERSION
ARG PROFILE
LABEL variant="distroless" profile="${PROFILE}"
COPY --from=builder /rootfs /
COPY config/ /etc/nginx/
ENV PATH="/usr/local/bin:/usr/sbin:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/lib:/usr/lib" \
    OPENSSL_CONF=/usr/local/ssl/openssl.cnf
EXPOSE 80 443
STOPSIGNAL SIGQUIT
USER nginx
WORKDIR /var/cache/nginx
ENTRYPOINT ["nginx", "-g", "daemon off;"]

FROM ${FIPS_IMAGE} AS standard
ARG NGINX_VERSION
ARG PROFILE
USER root
LABEL variant="standard" profile="${PROFILE}"
COPY --from=builder /rootfs /
COPY config/ /etc/nginx/
ENV PATH="/usr/local/bin:/usr/sbin:${PATH}" \
    LD_LIBRARY_PATH="/usr/local/lib:/usr/lib" \
    OPENSSL_CONF=/usr/local/ssl/openssl.cnf
EXPOSE 80 443
STOPSIGNAL SIGQUIT
USER nginx
WORKDIR /var/cache/nginx
ENTRYPOINT ["nginx", "-g", "daemon off;"]