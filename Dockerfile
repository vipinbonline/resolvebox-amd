FROM quay.io/fedora/fedora-toolbox:44

# SPDX-License-Identifier: Apache-2.0
#
# Derived from the davincibox Containerfile:
# https://github.com/zelikos/davincibox
#
# Substantially modified for resolvebox-amd.
#
# Copyright 2026 Vipin Balakrishnan (modifications only)

LABEL com.github.containers.toolbox="true" \
    usage="AMD-only DaVinci Resolve image for Distrobox" \
    summary="DaVinci Resolve runtime dependencies with AMD ROCm OpenCL"

COPY system_files /

COPY davinci-dependencies /tmp/davinci-dependencies

RUN set -eux; \
    grep -vE '^[[:space:]]*(#|$)' /tmp/davinci-dependencies \
        | xargs -r dnf -y install; \
    rm -f /tmp/davinci-dependencies; \
    dnf -y clean all; \
    rm -rf \
        /var/cache/dnf \
        /var/log/dnf* \
        /tmp/* \
        /var/tmp/*