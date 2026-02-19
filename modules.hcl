
variable "modules_db" {
    default = {
    # --------------------------------------------------------------------------
    # INTERNAL MODULES (Bundled with Nginx Source)
    # --------------------------------------------------------------------------
        "http_image_filter" = { 
      type = "int", 
      flag = "--with-http_image_filter_module=dynamic" 
    }
        "http_xslt" = { 
      type = "int", 
      flag = "--with-http_xslt_module=dynamic" 
    }
        "http_geoip" = { 
      type = "int", 
      flag = "--with-http_geoip_module=dynamic" 
    }
        "mail" = { 
      type = "int", 
      flag = "--with-mail=dynamic" 
    }
        "stream" = { 
      type = "int", 
      flag = "--with-stream=dynamic" 
    }
        "stream_geoip" = { 
      type = "int", 
      flag = "--with-stream_geoip_module=dynamic" 
    }
        "http_perl" = { 
      type = "int", 
      flag = "--with-http_perl_module=dynamic" 
    }

    # --------------------------------------------------------------------------
    # EXTERNAL MODULES (3rd-party Sources with Integrity Verification)
    # --------------------------------------------------------------------------
    
    # NJS - Nginx JavaScript
        "njs" = {
      type = "ext",
      url  = "https://github.com/nginx/njs/archive/refs/tags/0.9.5.tar.gz",
      sha  = "351a857abfd48c1e5e9c5d01bea046f3cbd2aa1c8ba956703920a5d57e046d7a",
      flag = "--add-dynamic-module={{DIR}}/nginx"
    }

    # Headers More - Advanced Header Manipulation
        "headers_more" = {
      type = "ext",
      url  = "https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/v0.38.tar.gz",
      sha  = "febf7271c0c3de69adbd02c1e98ee43e91a60eeb6b27abfb77b5b206fda5215a",
      flag = "--add-dynamic-module={{DIR}}"
    }

    # Echo - Debugging/Direct Body Output
        "echo" = {
      type = "ext",
      url  = "https://github.com/openresty/echo-nginx-module/archive/refs/tags/v0.64.tar.gz",
      sha  = "6f43f56d7e7e8526716bbda06b300f0119912eede47b3a48bb948252a1fb38c8",
      flag = "--add-dynamic-module={{DIR}}"
    }

    # Brotli - Modern Google Compression
        "brotli" = {
      type = "ext",
      url  = "https://github.com/google/ngx_brotli/archive/refs/tags/v1.0.0rc.tar.gz",
      sha  = "c85cdcfd76703c95aa4204ee4c2e619aa5b075cac18f428202f65552104add3b",
      flag = "--add-dynamic-module={{DIR}}"
    }

    # GeoIP2 - Modern MaxMind GeoIP support
        "geoip2" = {
      type = "ext",
      url  = "https://github.com/leev/ngx_http_geoip2_module/archive/refs/tags/3.4.tar.gz",
      sha  = "ad72fc23348d715a330994984531fab9b3606e160483236737f9a4a6957d9452",
      flag = "--add-dynamic-module={{DIR}}"
    }

    # Cache Purge - Manual cache invalidation
        "cache_purge" = {
      type = "ext",
      url  = "https://github.com/FRiCKLE/ngx_cache_purge/archive/refs/tags/2.3.tar.gz",
      sha  = "cb7d5f22919c613f1f03341a1aeb960965269302e9eb23425ccaabd2f5dcbbec",
      flag = "--add-dynamic-module={{DIR}}"
    }

    # Subs Filter - Dynamic search and replace in body
        "subs_filter" = {
      type = "ext",
      url  = "https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/refs/tags/v0.6.4.tar.gz",
      sha  = "ed4ddbcf0c434f4a1e97b61251a63ace759792764bd5cb79ff20efe348db8db3",
      flag = "--add-dynamic-module={{DIR}}"
    }

    # Cookie Flag - Security-focused cookie hardening
        "cookie_flag" = {
      type = "ext",
      url  = "https://github.com/AirisX/nginx_cookie_flag_module/archive/refs/tags/v1.1.0.tar.gz",
      sha  = "9915ad1cf0734cc5b357b0d9ea92fec94764b4bf22f4dce185cbd65feda30ec1",
      flag = "--add-dynamic-module={{DIR}}"
    }

    # Auth PAM - System-level authentication
        "auth_pam" = {
      type = "ext",
      url  = "https://github.com/sto/ngx_http_auth_pam_module/archive/refs/tags/v1.5.5.tar.gz",
      sha  = "98a71617d9119ae784993e3789ce8766fdf2ff2479691f3dc6cf8d8763f8d364",
      flag = "--add-dynamic-module={{DIR}}"
    }

    # WebDAV Extended - Extended file management
        "dav_ext" = {
      type = "ext",
      url  = "https://github.com/arut/nginx-dav-ext-module/archive/refs/tags/v3.0.0.tar.gz",
      sha  = "d2499d94d82d4e4eac8425d799e52883131ae86a956524040ff2fd230ef9f859",
      flag = "--add-dynamic-module={{DIR}}"
    }

    # VTS - Virtual Host Traffic Status Metrics
        "vts" = {
      type = "ext",
      url  = "https://github.com/vozlt/nginx-module-vts/archive/refs/tags/v0.2.2.tar.gz",
      sha  = "-",
      flag = "--add-dynamic-module={{DIR}}"
    }
    }
}