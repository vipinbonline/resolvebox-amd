# Attribution

## resolvebox-amd

`resolvebox-amd` is an independently maintained AMD/ROCm-focused container and integration project for installing and running DaVinci Resolve on Linux.

The project contains original work as well as software derived from the upstream `davincibox` project.

## Upstream Project

`resolvebox-amd` is derived from:

**davincibox**
https://github.com/zelikos/davincibox

`davincibox` is distributed under the Apache License, Version 2.0.

The original davincibox project and its contributors retain copyright in their respective contributions.

### Upstream Base Revision

The original development base for `resolvebox-amd` was the following revision of the upstream `davincibox` project:

**Base commit:**
`d6b5f768200a2e67f01f961e3de82e40f712a5b6`

**Permanent commit reference:**
https://github.com/zelikos/davincibox/commit/d6b5f768200a2e67f01f961e3de82e40f712a5b6

This commit identifies the upstream source revision used as the original development base for `resolvebox-amd`.

Subsequent modifications and original contributions are maintained in the `resolvebox-amd` repository.

`resolvebox-amd` contains substantial modifications to the upstream project, including changes related to:

* AMD/ROCm-focused GPU support
* ROCm OpenCL configuration
* Distrobox-only container management
* Distrobox Assemble configuration
* local Podman image construction
* configurable container naming
* installation workflow
* launcher integration
* GPU/OpenCL diagnostics
* runtime integration and related tooling

These modifications do not transfer ownership of the original davincibox contributions to the maintainers of `resolvebox-amd`.

## Upstream Acknowledgements

The upstream davincibox project acknowledges work and information from other contributors and projects.

### Sean Davis (`bluesabre`)

The upstream davincibox project states that its Containerfile and setup scripts were heavily based on DaVinci Resolve Linux dependency and installation information compiled by Sean Davis (`bluesabre`).

Original referenced Gist:

https://gist.github.com/bluesabre/8814afece711b0ca49de34c41e50b296

GitHub profile:

https://github.com/bluesabre

### Jorge Castro and Universal Blue

The upstream davincibox project also credits Jorge Castro and Universal Blue.

Jorge Castro's article about declarative Distrobox environments helped inspire the upstream project:

https://www.ypsidanger.com/declaring-your-own-personal-distroboxes/

Universal Blue's Boxkit was used as a basis for portions of the upstream project's CI approach:

https://github.com/ublue-os/boxkit

For the authoritative upstream history and acknowledgements, see:

https://github.com/zelikos/davincibox

## resolvebox-amd Contributions

Copyright 2026 Vipin Balakrishnan

This copyright applies only to modifications and original contributions introduced as part of `resolvebox-amd`.

It does not claim ownership of:

* original davincibox contributions
* Fedora
* Distrobox
* Podman
* AMD ROCm
* OpenCL implementations
* DaVinci Resolve
* Blackmagic Design software or assets
* other third-party software used by or installed through this project

Unless otherwise indicated, source code and other original material contributed specifically to `resolvebox-amd` are distributed under the Apache License, Version 2.0.

See the repository's `LICENSE` file for the complete license terms.

## Third-Party Software

`resolvebox-amd` builds a container environment using third-party software.

This may include components and packages from:

* Fedora
* Distrobox
* Podman
* AMD ROCm
* OpenCL implementations
* system libraries
* desktop integration components
* other runtime dependencies

These components remain subject to their own respective copyright and license terms.

The Apache License 2.0 applied to `resolvebox-amd` does **not** relicense those third-party components.

Package names appearing in `davinci-dependencies` identify dependencies required by the project and do not imply ownership of those packages by the `resolvebox-amd` project.

If a prebuilt container image is distributed, the licenses and redistribution requirements of the software contained in that image must be considered separately.

## DaVinci Resolve

DaVinci Resolve is proprietary software developed by Blackmagic Design Pty Ltd.

DaVinci Resolve is **not licensed under the Apache License 2.0** and is not part of the software licensed by `resolvebox-amd`.

This project does not distribute the DaVinci Resolve installer or DaVinci Resolve application binaries.

Users must obtain DaVinci Resolve separately from Blackmagic Design and are responsible for complying with the license agreement applicable to their copy of DaVinci Resolve.

Nothing in the `resolvebox-amd` license, this attribution file, or the project documentation grants permission to copy, redistribute, modify, sublicense, or otherwise use DaVinci Resolve beyond the rights granted by Blackmagic Design and applicable law.

## Trademarks

DaVinci Resolve, Blackmagic Design, AMD, AMD ROCm, Fedora, Distrobox, Podman, and other product or company names referenced by this project may be trademarks or registered trademarks of their respective owners.

Their use in this project is solely for identification, compatibility description, technical documentation, and attribution.

No trademark rights are granted by the Apache License 2.0.

## Independence and Affiliation

`resolvebox-amd` is an independent community project.

It is not affiliated with, sponsored by, certified by, approved by, or endorsed by:

* Blackmagic Design Pty Ltd.
* Advanced Micro Devices, Inc.
* the Fedora Project or Red Hat
* the Distrobox project
* the Podman project
* the upstream davincibox project
* their respective contributors or maintainers

References to these projects, companies, products, and technologies are descriptive only.

## Additional Information

For the project license, see:

`LICENSE`

For the concise attribution notice distributed with the project, see:

`NOTICE`

For project usage and installation information, see:

`README.md`
