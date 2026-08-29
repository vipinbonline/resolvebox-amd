## Installation

First, download the DaVinci Resolve Linux installer directly from Blackmagic Design.

Make it executable if required:

```bash
chmod +x DaVinci_Resolve_*_Linux.run
```

Then run:

```bash
./setup.sh resolvebox.ini resolvebox ./DaVinci_Resolve_21.0.4_Linux.run
```

The exact DaVinci Resolve version is not hardcoded. Replace the installer filename with the version you downloaded.

### Important: Compatibility Workaround Confirmation

During installation, `resolvebox-amd` will display a confirmation before installing and configuring DaVinci Resolve.

You will see a message similar to:

```text
DaVinci Resolve compatibility workaround

resolvebox-amd requires a compatibility workaround for the current
container environment.

The workaround modifies ELF dynamic dependency metadata in your locally
installed copy of DaVinci Resolve using patchelf.

Without this workaround, DaVinci Resolve may not start or operate
correctly in this resolvebox environment.

DaVinci Resolve remains subject to Blackmagic Design's applicable
license terms. Review those terms before continuing.

Continue with installation and apply the compatibility workaround? [y/N]
```

> [!IMPORTANT]
> The compatibility workaround is required for the currently supported `resolvebox-amd` environment. If you decline it, the installation will stop before DaVinci Resolve is installed.
>
> The confirmation exists because the workaround modifies files belonging to the user's separately obtained DaVinci Resolve installation. It is not an acceptance of Blackmagic Design's license on the user's behalf and does not grant additional rights to modify DaVinci Resolve.

If you understand the modification and want to continue with the `resolvebox-amd` setup, answer:

```text
y
```

or:

```text
yes
```

The setup process then:

1. Reads the selected Distrobox configuration.
2. Builds the local Podman image.
3. Creates the Distrobox container.
4. Extracts the user-provided DaVinci Resolve installer.
5. Explains the required compatibility workaround and requests confirmation.
6. Installs DaVinci Resolve inside the container.
7. Applies the container compatibility workaround using `patchelf`.
8. Applies any additional compatibility handling required by the supported environment.
9. Optionally creates host launcher integration.

## DaVinci Resolve Compatibility Workaround

DaVinci Resolve is proprietary software developed by Blackmagic Design Pty Ltd. and is not distributed as part of `resolvebox-amd`.

### Why is the workaround needed?

DaVinci Resolve is built for particular Linux runtime environments. The libraries available inside the Fedora/Distrobox environment used by `resolvebox-amd` can differ from the environment expected by DaVinci Resolve.

Without additional compatibility handling, DaVinci Resolve may fail to start or some components may not function correctly.

`resolvebox-amd` therefore uses `patchelf` to add required system libraries to the ELF dynamic dependency metadata of the user's locally installed DaVinci Resolve executables.

The current workaround adds dependencies for system libraries including:

```text
libglib-2.0.so.0
libgdk_pixbuf-2.0.so.0
libgio-2.0.so.0
libgmodule-2.0.so.0
```

This workaround is part of making DaVinci Resolve operate correctly in the currently supported `resolvebox-amd` container environment.

### What the workaround does

The workaround:

* operates only on a DaVinci Resolve installation supplied and installed by the user;
* modifies ELF dependency metadata in the user's local DaVinci Resolve installation;
* does not distribute modified DaVinci Resolve binaries;
* does not distribute the DaVinci Resolve installer;
* does not provide, bypass, remove, or interfere with DaVinci Resolve Studio activation or licensing;
* is intended solely as a Linux/container runtime compatibility workaround;
* is not represented as an official or Blackmagic-supported modification.

The setup may also apply compatibility handling to certain DaVinci Resolve companion-program components when required by the container environment.

### Why does setup ask for confirmation?

DaVinci Resolve and the `resolvebox-amd` scripts are licensed separately.

The `resolvebox-amd` source code and applicable upstream davincibox material are distributed under the Apache License 2.0.

DaVinci Resolve itself remains proprietary software licensed by Blackmagic Design.

For that reason, `resolvebox-amd` explicitly informs the user before performing an operation that modifies files in their separately installed copy of DaVinci Resolve.

The confirmation is intended to make the modification visible and deliberate. It does not replace, alter, or override Blackmagic Design's license terms.

Users are responsible for reviewing and complying with the license terms applicable to their copy of DaVinci Resolve.

The Apache License 2.0 covering `resolvebox-amd` does not grant permission to modify, redistribute, sublicense, or otherwise use DaVinci Resolve beyond rights provided by Blackmagic Design or applicable law.

Where a reliable non-modifying runtime solution is available, `resolvebox-amd` should prefer that approach over modifying DaVinci Resolve binaries.
