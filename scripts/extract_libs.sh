#!/usr/bin/env bash
set -e

TARGET_ROOTFS="/rootfs"

mkdir -p "${TARGET_ROOTFS}/lib" \
         "${TARGET_ROOTFS}/usr/lib" \
         "${TARGET_ROOTFS}/usr/local/lib"

declare -A PROCESSED_LIBS

extract_recursive() {
    local file=$1
    
    local libs=$(ldd "$file" | grep "=> /" | awk '{print $3}')
    
    for lib in $libs; do
        if [[ -z "${PROCESSED_LIBS[$lib]}" ]]; then
            PROCESSED_LIBS[$lib]=1
            
            if [[ -f "$lib" ]]; then
                local destination=""
                
                if [[ "$lib" == /usr/local/lib/* ]]; then
                    destination="${TARGET_ROOTFS}/usr/local/lib"
                elif [[ "$lib" == /usr/lib/* ]]; then
                    destination="${TARGET_ROOTFS}/usr/lib"
                else
                    destination="${TARGET_ROOTFS}/lib"
                fi
                
                cp -vL "$lib" "$destination/"
                
                extract_recursive "$lib"
            fi
        fi
    done
}

echo ">>> Starting Recursive Library Extraction..."

for entry in "$@"; do
    if [[ -f "$entry" ]]; then
        echo "  [+] Scanning: $entry"
        extract_recursive "$entry"
    else
        echo "  [-] Skipping: $entry (Not found)"
    fi
done

echo ">>> Updating ld.so.cache for the new RootFS..."

/sbin/ldconfig -r "${TARGET_ROOTFS}"

echo ">>> Library extraction complete. Total libs tracked: ${#PROCESSED_LIBS[@]}"
