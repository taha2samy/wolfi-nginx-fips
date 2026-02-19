# ==============================================================================
# NGINX BUILD PROFILES (LOGICAL GROUPING)
# ==============================================================================
# This file defines which modules from modules.hcl are included in each variant.
# Core:   Minimalist, high-performance base.
# Full:   Standard distribution with all internal dynamic modules.
# Extras: The "Batteries-Included" version with all 3rd-party modules.
# ==============================================================================

variable "profiles" {
  default = {
    
    # 1. CORE: The leanest possible Nginx (Strictly FIPS + Core Features)
    "core" = []

    # 2. FULL: Includes all internal modules provided by Nginx source (as Dynamic)
    "full" = [
      "http_image_filter",
      "http_xslt",
      "http_geoip",
      "mail",
      "stream",
      "stream_geoip",
      "http_perl",
      "njs"
    ]

    # 3. EXTRAS: Everything in 'Full' + All 3rd-party security & performance modules
    "extras" = [
      # Inherited from Full
      "http_image_filter",
      "http_xslt",
      "http_geoip",
      "mail",
      "stream",
      "stream_geoip",
      "http_perl",
      "njs",
      
      # External Extras
      "headers_more",
      "echo",
      "brotli",
      "geoip2",
      "cache_purge",
      "subs_filter",
      "cookie_flag",
      "auth_pam",
      "dav_ext",
      "vts"
    ]
  }
}