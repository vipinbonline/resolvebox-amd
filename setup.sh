#!/usr/bin/env bash


#SPDX-License-Identifier: Apache-2.0


#Derived from davincibox:
#https://github.com/zelikos/davincibox


#Modified for resolvebox-amd, 2026.
#This file contains changes from the upstream version.


# Copyright 2026 Vipin Balakrishnan (modifications only)




set -Eeuo pipefail
IFS=$'\n\t'
umask 022

readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1
    pwd -P
)"
readonly DOCKERFILE="$(
    find "$SCRIPT_DIR" \
        -maxdepth 1 \
        -type f \
        -iname 'dockerfile' \
        -print \
        -quit
)"
INI_FILE=""
CONTAINER_NAME=""
IMAGE_NAME=""
EXTRACT_DIR=""

# ==============================================================================
# Logging / errors
# ==============================================================================

log() {
    printf '[%s] %s\n' "$SCRIPT_NAME" "$*"
}

warn() {
    printf '[%s] WARNING: %s\n' "$SCRIPT_NAME" "$*" >&2
}

die() {
    printf '[%s] ERROR: %s\n' "$SCRIPT_NAME" "$*" >&2
    exit 1
}

usage() {
    cat <<EOF_USAGE
Usage:
  $SCRIPT_NAME <distrobox.ini> <container-name> <DaVinci_Resolve_Linux.run>
  $SCRIPT_NAME <distrobox.ini> <container-name> remove
  $SCRIPT_NAME <distrobox.ini> <container-name> rebuild <DaVinci_Resolve_Linux.run>

Examples:
  ./$SCRIPT_NAME distrobox.ini resolvebox DaVinci_Resolve_20_Linux.run
  ./$SCRIPT_NAME distrobox.ini resolvebox remove
  ./$SCRIPT_NAME distrobox.ini resolvebox rebuild DaVinci_Resolve_20_Linux.run

Manifest example:
  [resolvebox]
  image=localhost/resolvebox-amd:44
  pull=false
  root=false
  init=false
  nvidia=false

The selected INI section name IS the Distrobox/container name.
The image= value from that same section is used as the Podman build tag.
EOF_USAGE
}

cleanup() {
    if [[ -n "$EXTRACT_DIR" && -d "$EXTRACT_DIR" ]]; then
        rm -rf -- "$EXTRACT_DIR"
    fi
}
trap cleanup EXIT

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}



# ==============================================================================
# INI handling
# ==============================================================================


trim() {
    local value="$1"

    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"

    printf '%s' "$value"
}

unquote() {
    local value="$1"

    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
        value="${value:1:${#value}-2}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
        value="${value:1:${#value}-2}"
    fi

    printf '%s' "$value"
}

# Read only the values setup.sh needs from one Distrobox section.
#
# Example:
#
#   [resolvebox]
#   image=localhost/resolvebox-amd:44
#   pull=false
#
# The section name is the Distrobox/container name.
read_manifest_section() {
    local file="$1"
    local wanted_section="$2"

    local line=""
    local current_section=""
    local key=""
    local value=""
    local section_found=false
    local pull_setting=""

    IMAGE_NAME=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="$(trim "$line")"

        # Ignore blank lines and comments.
        [[ -z "$line" || "$line" == \#* ]] && continue

        # Section header, for example: [davincibox]
        if [[ "$line" =~ ^\[([^]]+)\][[:space:]]*(#.*)?$ ]]; then
            current_section="$(trim "${BASH_REMATCH[1]}")"

            if [[ "$current_section" == "$wanted_section" ]]; then
                section_found=true
            fi

            continue
        fi

        # Ignore values belonging to other sections.
        [[ "$current_section" == "$wanted_section" ]] || continue

        # Ignore malformed/non key=value lines.
        [[ "$line" == *=* ]] || continue

        key="$(trim "${line%%=*}")"
        value="$(trim "${line#*=}")"
        value="$(unquote "$value")"

        case "$key" in
            image)
                IMAGE_NAME="$value"
                ;;
            pull)
                pull_setting="${value,,}"
                ;;
        esac
    done < "$file"

    $section_found \
        || die "Section [$wanted_section] was not found in $file"

    [[ -n "$IMAGE_NAME" ]] \
        || die "Section [$wanted_section] does not define image= in $file"

    [[ "$IMAGE_NAME" != *[[:space:]]* ]] \
        || die "Invalid image= value in [$wanted_section]: '$IMAGE_NAME'"

    if [[ "$pull_setting" == "true" ]]; then
        die "[$wanted_section] has pull=true. Set pull=false because setup.sh builds '$IMAGE_NAME' locally with Podman."
    fi
}

resolve_manifest() {
    local requested_ini="$1"
    local requested_container="$2"

    [[ -f "$requested_ini" ]] \
        || die "INI file not found: $requested_ini"

    INI_FILE="$(realpath -e -- "$requested_ini")" \
        || die "Unable to resolve INI file: $requested_ini"

    CONTAINER_NAME="$requested_container"

    [[ "$CONTAINER_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] \
        || die "Invalid container name/INI section: $CONTAINER_NAME"

    read_manifest_section "$INI_FILE" "$CONTAINER_NAME"

    log "Configuration"
    log "  Manifest  : $INI_FILE"
    log "  Distrobox : $CONTAINER_NAME"
    log "  Image     : $IMAGE_NAME"
}

# ==============================================================================
# Requirements
# ==============================================================================

check_base_requirements() {
    require_command distrobox
    require_command realpath
    require_command sed
    require_command cut
    require_command grep
}

check_build_requirements() {
    require_command podman
    require_command mktemp

    [[ -f "$DOCKERFILE" ]] \
        || die "Dockerfile not found: $DOCKERFILE"

    [[ -f "${SCRIPT_DIR}/davinci-dependencies" ]] \
        || die "davinci-dependencies not found: ${SCRIPT_DIR}/davinci-dependencies"

    [[ -d "${SCRIPT_DIR}/system_files" ]] \
        || die "system_files directory not found: ${SCRIPT_DIR}/system_files"
}

# ==============================================================================
# Podman image
# ==============================================================================

build_image() {
    log "Building Podman image '$IMAGE_NAME'..."

    podman build \
        --file "$DOCKERFILE" \
        --tag "$IMAGE_NAME" \
        "$SCRIPT_DIR"

    podman image exists "$IMAGE_NAME" \
        || die "Podman build completed but image '$IMAGE_NAME' cannot be found."

    log "Image ready: $IMAGE_NAME"
}

# ==============================================================================
# Distrobox lifecycle
# ==============================================================================

container_exists() {
    distrobox list --no-color 2>/dev/null \
        | sed '1d' \
        | cut -d '|' -f 2 \
        | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
        | grep -Fxq -- "$CONTAINER_NAME"
}

create_container() {
    if container_exists; then
        die "Distrobox '$CONTAINER_NAME' already exists. Use 'upgrade' to rebuild it, or 'remove' first."
    fi

    log "Creating Distrobox '$CONTAINER_NAME' from [$CONTAINER_NAME]..."

    distrobox assemble create \
        --file "$INI_FILE" \
        --name "$CONTAINER_NAME"

    # Enter once to complete Distrobox first-start initialization.
    distrobox enter \
        --name "$CONTAINER_NAME" \
        -- true

    log "Distrobox created: $CONTAINER_NAME"
}

remove_launcher() {
    if ! container_exists; then
        return 0
    fi

    if distrobox enter \
        --name "$CONTAINER_NAME" \
        -- test -x /usr/bin/add-davinci-launcher; then

        log "Removing DaVinci desktop launchers..."

        distrobox enter \
            --name "$CONTAINER_NAME" \
            -- /usr/bin/add-davinci-launcher remove "$CONTAINER_NAME" \
            || warn "Launcher cleanup failed; continuing with container removal."
    fi
}

remove_container() {
    if ! container_exists; then
        log "Distrobox '$CONTAINER_NAME' does not exist. Nothing to remove."
        return 0
    fi

    remove_launcher

    log "Removing Distrobox '$CONTAINER_NAME'..."

    distrobox assemble rm \
        --file "$INI_FILE" \
        --name "$CONTAINER_NAME"

    log "Distrobox removed: $CONTAINER_NAME"
}

# ==============================================================================
# DaVinci installer
# ==============================================================================

resolve_installer() {
    local requested_installer="$1"
    local resolved_installer

    [[ -f "$requested_installer" ]] \
        || die "DaVinci Resolve installer not found: $requested_installer"

    resolved_installer="$(realpath -e -- "$requested_installer")" \
        || die "Unable to resolve installer path: $requested_installer"

    [[ -x "$resolved_installer" ]] \
        || die "Installer is not executable: $resolved_installer. Run: chmod +x '$requested_installer'"

    printf '%s\n' "$resolved_installer"
}

install_davinci() {
    local installer="$1"
    local extracted_app
    local container_installer

    EXTRACT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/davincibox-installer.XXXXXX")"

    log "Extracting DaVinci Resolve installer..."

    (
        cd "$EXTRACT_DIR"
        "$installer" --appimage-extract >/dev/null
    )

    extracted_app="${EXTRACT_DIR}/squashfs-root/AppRun"

    [[ -f "$extracted_app" ]] \
        || die "Installer extraction completed, but AppRun was not found: $extracted_app"

    # Distrobox exposes the host filesystem under /run/host.
    container_installer="/run/host${extracted_app}"

    log "Installing DaVinci Resolve inside '$CONTAINER_NAME'..."

    distrobox enter \
        --name "$CONTAINER_NAME" \
        -- /usr/bin/setup-davinci \
        "$container_installer" \
        "$CONTAINER_NAME"

    log "DaVinci Resolve installation completed."
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    local operation
    local installer

    [[ $# -ge 3 ]] || {
        usage
        exit 2
    }

    check_base_requirements

    # Argument 1: manifest file
    # Argument 2: section name == Distrobox/container name
    resolve_manifest "$1" "$2"
    shift 2

    operation="$1"
    shift

    case "$operation" in
        remove)
            [[ $# -eq 0 ]] \
                || die "Usage: $SCRIPT_NAME <distrobox.ini> <container-name> remove"

            remove_container
            ;;

        rebuild)
            [[ $# -eq 1 ]] \
                || die "Usage: $SCRIPT_NAME <distrobox.ini> <container-name> rebuild <DaVinci_Resolve_Linux.run>"

            check_build_requirements
            installer="$(resolve_installer "$1")"

            remove_container
            build_image
            create_container
            install_davinci "$installer"
            ;;

        *)
            [[ $# -eq 0 ]] \
                || die "Usage: $SCRIPT_NAME <distrobox.ini> <container-name> <DaVinci_Resolve_Linux.run>"

            check_build_requirements
            installer="$(resolve_installer "$operation")"

            build_image
            create_container
            install_davinci "$installer"
            ;;
    esac
}

main "$@"
