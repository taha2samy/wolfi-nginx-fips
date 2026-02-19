# ==============================================================================
# NGINX FIPS ORCHESTRATOR (DOCKER BAKE)
# ==============================================================================

# --- Global Variables ---
variable "REGISTRY" { default = "ghcr.io" }
variable "OWNER" { default = "taha2samy" }
variable "REPO" { default = "wolfi-nginx-fips" }
variable "NGINX_VERSION" { default = "1.27.3" }

# --- Base Images (From our previous FIPS project) ---
variable "FIPS_BASE" { default = "ghcr.io/${OWNER}/wolfi-openssl-fips:3.5.5" }
variable "FIPS_STATIC" { default = "ghcr.io/${OWNER}/wolfi-openssl-fips:3.5.5-distroless" }

# ------------------------------------------------------------------------------
# SHARED BUILD CONFIGURATION
# ------------------------------------------------------------------------------
target "_common" {
    context    = "."
    dockerfile = "Dockerfile"
    platforms  = ["linux/amd64", "linux/arm64"]
  
    args = {
        NGINX_VERSION         = "${NGINX_VERSION}"
        FIPS_IMAGE            = "${FIPS_BASE}"
        FIPS_IMAGE_DISTROLESS = "${FIPS_STATIC}"
        MODULES_JSON          = jsonencode(modules_db)
    }

    attest = [
    "type=sbom,generator=docker/buildkit-syft-scanner",
    "type=provenance,mode=max"
  ]
}

# ------------------------------------------------------------------------------
# GROUPS (Execution Entry Points)
# ------------------------------------------------------------------------------
group "default" {
    targets = ["core", "full", "extras"]
}

group "core" { targets = ["core-distroless", "core-standard"] }
group "full" { targets = ["full-distroless", "full-standard"] }
group "extras" { targets = ["extras-distroless", "extras-standard"] }

# ------------------------------------------------------------------------------
# TARGET VARIANTS (The Production Matrix)
# ------------------------------------------------------------------------------

# --- [CORE] Variants ---
target "core-distroless" {
    inherits = ["_common"]
    target   = "distroless"
    args     = { PROFILE = "core", ENABLED_MODULES = jsonencode(profiles.core) }
    tags     = ["${REGISTRY}/${OWNER}/${REPO}:${NGINX_VERSION}-core", "${REGISTRY}/${OWNER}/${REPO}:core"]
}

target "core-standard" {
    inherits = ["_common"]
    target   = "standard"
    args     = { PROFILE = "core", ENABLED_MODULES = jsonencode(profiles.core) }
    tags     = ["${REGISTRY}/${OWNER}/${REPO}:${NGINX_VERSION}-core-std", "${REGISTRY}/${OWNER}/${REPO}:core-std"]
}

# --- [FULL] Variants ---
target "full-distroless" {
    inherits = ["_common"]
    target   = "distroless"
    args     = { PROFILE = "full", ENABLED_MODULES = jsonencode(profiles.full) }
    tags     = ["${REGISTRY}/${OWNER}/${REPO}:${NGINX_VERSION}-full", "${REGISTRY}/${OWNER}/${REPO}:full"]
}

target "full-standard" {
    inherits = ["_common"]
    target   = "standard"
    args     = { PROFILE = "full", ENABLED_MODULES = jsonencode(profiles.full) }
    tags     = ["${REGISTRY}/${OWNER}/${REPO}:${NGINX_VERSION}-full-std", "${REGISTRY}/${OWNER}/${REPO}:full-std"]
}

# --- [EXTRAS] Variants ---
target "extras-distroless" {
    inherits = ["_common"]
    target   = "distroless"
    args     = { PROFILE = "extras", ENABLED_MODULES = jsonencode(profiles.extras) }
    tags     = ["${REGISTRY}/${OWNER}/${REPO}:${NGINX_VERSION}-extras", "${REGISTRY}/${OWNER}/${REPO}:extras"]
}

target "extras-standard" {
    inherits = ["_common"]
    target   = "standard"
    args     = { PROFILE = "extras", ENABLED_MODULES = jsonencode(profiles.extras) }
    tags     = ["${REGISTRY}/${OWNER}/${REPO}:${NGINX_VERSION}-extras-std", "${REGISTRY}/${OWNER}/${REPO}:extras-std"]
}