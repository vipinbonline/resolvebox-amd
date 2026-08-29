# resolvebox-amd

`resolvebox-amd` provides an AMD/ROCm-focused Distrobox environment for installing and running DaVinci Resolve on Linux.

It is an independently maintained derivative of [zelikos/davincibox](https://github.com/zelikos/davincibox), with substantial changes to the container build process, GPU handling, Distrobox integration, installation workflow, and launcher tooling.

DaVinci Resolve itself is **not included or distributed by this project**. Users must obtain the Linux installer directly from Blackmagic Design.

---

## Features

* AMD/ROCm-focused environment
* Distrobox-only workflow
* Distrobox Assemble configuration
* Local container image builds using Podman
* Configurable container names
* ROCm OpenCL support
* Host integration for DaVinci Resolve launchers
* GPU/OpenCL diagnostic helper
* Container rebuild and removal workflows
* Separate container HOME support
* Optional Niri/XWayland launcher workaround
* Arch Linux + Niri host integration for the optional Niri helper
* No NVIDIA-specific handling
* No Toolbox workflow

---

## How the Project Works

At a high level, `resolvebox-amd` works like this:

```text
GitHub repository
        │
        ▼
Dockerfile + dependencies
        │
        ▼
Local Podman image
localhost/resolvebox-amd:44
        │
        ▼
Distrobox Assemble
resolvebox.ini
        │
        ▼
Distrobox container
        │
        ▼
User-provided DaVinci Resolve installer
        │
        ▼
DaVinci Resolve installation
        │
        ▼
Container compatibility workaround
        │
        ▼
AMD/ROCm OpenCL configuration
        │
        ▼
Optional desktop launcher
        │
        ▼
DaVinci Resolve
```

The DaVinci Resolve installer is supplied by the user and is never downloaded or distributed by this repository.

For Niri users, the optional host-side launch path adds one additional layer:

```text
DaVinci Resolve inside Distrobox
        │
        ▼
run-davinci
        │
        ▼
X11 / Qt xcb
        │
        ▼
XWayland
        │
        ▼
xwayland-satellite
        │
        ▼
davinci-resolve-niri
(window detection / repair)
        │
        ▼
Niri
```

The Niri helper does not replace the normal container setup. It is used **after**
`resolvebox-amd` has been installed and is only needed on a Niri host when the
Resolve Project Manager is affected by the XWayland/xwayland-satellite window
behavior described later in this README.

---

# Requirements

The host system should provide:

* Linux
* Distrobox
* Podman
* Git
* an AMD GPU supported by the required ROCm/OpenCL stack
* sufficient disk space for the container and DaVinci Resolve
* a DaVinci Resolve Linux installer obtained directly from Blackmagic Design

You can check the main required commands with:

```bash
command -v git
command -v distrobox
command -v podman
```

The project builds its container image locally using Podman.

## Primary Tested Host

The primary host environment used and tested for this project is **Arch Linux**.

The container created by `resolvebox-amd` is Fedora-based, but the commands used
to install **host-side prerequisites** in this README are written for Arch Linux.

Other Linux distributions supported by Distrobox and Podman may also work, but
their host package names and setup steps can differ.

On Arch Linux, the main host requirements can be installed with:

```bash
sudo pacman -S --needed \
    git \
    distrobox \
    podman
```

## Additional Requirements for Niri Users

The optional `davinci-resolve-niri` script is specifically for users running the
**Niri scrolling Wayland compositor** on the host.

It is **not a requirement for normal `resolvebox-amd` usage**.

The Niri helper requires the following host-side commands/components:

| Command / component | Arch Linux package | Why it is needed |
|---|---|---|
| `niri` | `niri` | Queries Niri windows and verifies that the repaired Resolve window is visible |
| `xwayland-satellite` | `xwayland-satellite` | Provides XWayland integration for X11 applications under Niri |
| `Xwayland` | `xorg-xwayland` | Runs X11 applications in the Wayland session |
| `rofi` | `rofi` | Interactive Distrobox selection |
| `xwininfo` | `xorg-xwininfo` | Locates the Resolve X11 Project Manager window |
| `xprop` | `xorg-xprop` | Reads and removes the problematic X11 `WM_TRANSIENT_FOR` property |
| `xdotool` | `xdotool` | Unmaps and remaps the affected X11 window |
| `notify-send` | `libnotify` | Displays launcher status/error notifications |
| `flock` | `util-linux` | Prevents concurrent launcher instances |
| `awk` | `gawk` | Parses Distrobox and window information |
| `distrobox` | `distrobox` | Enters the selected Resolve container |

Install them on Arch Linux with:

```bash
sudo pacman -S --needed \
    niri \
    xwayland-satellite \
    xorg-xwayland \
    rofi \
    xorg-xwininfo \
    xorg-xprop \
    xdotool \
    libnotify \
    util-linux \
    gawk
```

> [!NOTE]
> `xwayland-satellite` depends on XWayland on Arch Linux. `xorg-xwayland` is
> shown explicitly above because the Resolve/Niri workaround depends on the
> X11 → XWayland → Niri path and it is useful to make that requirement clear.

A notification daemon or desktop shell capable of displaying freedesktop
notifications is also recommended so messages produced by `notify-send` are
visible.

The current `davinci-resolve-niri` script checks for `rofi` during startup even
when a Distrobox name is supplied on the command line, so `rofi` should currently
be considered a required dependency for the helper.

### Niri and XWayland

DaVinci Resolve is launched by this project with:

```text
QT_QPA_PLATFORM=xcb
```

so Resolve uses its X11/Qt `xcb` path in this environment.

On current Niri versions, X11 applications are handled using
`xwayland-satellite`. Niri 25.08 and newer can integrate
`xwayland-satellite >= 0.7` automatically: Niri creates the X11 sockets, exports
`DISPLAY`, and starts `xwayland-satellite` when an X11 client connects.

For a current Arch Linux/Niri installation, install `xwayland-satellite` and
allow Niri to manage this integration. Do **not** manually export a different
`DISPLAY` or manually start another `xwayland-satellite` instance unless you
specifically need a custom configuration.

Official Niri XWayland documentation:

https://github.com/niri-wm/niri/blob/main/docs/wiki/Xwayland.md

---

# Repository Structure

```text
resolvebox-amd/
├── LICENSE
├── NOTICE
├── ATTRIBUTION.md
├── README.md
├── Dockerfile
├── davinci-dependencies
├── resolvebox.ini
├── setup.sh
├── davinci-resolve-niri
└── system_files/
    └── usr/
        └── bin/
            ├── add-davinci-launcher
            ├── list-gpus
            ├── run-davinci
            └── setup-davinci
```

---

# What Each File Does

## `README.md`

The main project documentation.

It explains:

* project purpose
* installation
* configuration
* container naming
* custom HOME configuration
* compatibility workarounds
* running DaVinci Resolve
* optional Niri/XWayland host integration
* Niri launcher troubleshooting
* rebuild/removal
* licensing and attribution

---

## `LICENSE`

Contains the Apache License, Version 2.0 used by `resolvebox-amd` and applicable Apache-licensed upstream material.

The `LICENSE` file does **not** license DaVinci Resolve, ROCm, Fedora packages, or other third-party software.

---

## `NOTICE`

Contains concise project and upstream attribution information.

It identifies `davincibox` as the upstream project from which portions of `resolvebox-amd` were derived.

---

## `ATTRIBUTION.md`

Contains detailed project provenance and licensing boundaries.

It records:

* the upstream `davincibox` project
* the exact upstream base revision used by `resolvebox-amd`
* upstream acknowledgements
* project modifications
* third-party software boundaries
* DaVinci Resolve licensing boundaries
* trademark and affiliation information

The original development base is:

```text
d6b5f768200a2e67f01f961e3de82e40f712a5b6
```

See `ATTRIBUTION.md` for the complete provenance information.

---

## `Dockerfile`

Defines the local container image used by this project.

The Dockerfile:

1. starts from a Fedora Toolbox base image;
2. copies the project's container-side helper files;
3. reads the package list from `davinci-dependencies`;
4. installs the required runtime packages;
5. installs AMD/ROCm OpenCL support;
6. cleans package-manager caches and temporary files.

The resulting image is built locally using the name configured in `resolvebox.ini`.

For the default configuration:

```text
localhost/resolvebox-amd:44
```

No DaVinci Resolve installer or DaVinci Resolve application binaries are built into this image.

---

## `davinci-dependencies`

Contains the Fedora packages installed into the container.

Examples include:

```text
alsa-lib
libglvnd-egl
libglvnd-glx
ocl-icd
patchelf
rocm-opencl
switcheroo-control
```

The package list provides the libraries and runtime components required by the container environment.

The packages themselves remain subject to their own respective licenses.

---

## `resolvebox.ini`

This is the Distrobox Assemble manifest.

It defines how the container is created.

The default configuration looks similar to:

```ini
[resolvebox]

image=localhost/resolvebox-amd:44

pull=false
root=false
init=false
nvidia=false
replace=false
start_now=true
entry=false

home=/absolute/path/to/resolvebox-home
```

The configuration is explained in detail later in this README.

---

## `setup.sh`

This is the main script executed from the **host**.

It coordinates the complete setup process.

It:

1. reads `resolvebox.ini`;
2. reads the requested container section;
3. obtains the image name from the same section;
4. builds the local Podman image;
5. creates the Distrobox using Distrobox Assemble;
6. extracts the user-provided DaVinci Resolve installer;
7. makes the extracted installer available inside the container;
8. calls `setup-davinci` inside the container.

It also provides:

```text
install
rebuild
remove
```

workflows.

You normally interact with this project through `setup.sh`.

---

## `davinci-resolve-niri`

An optional **host-side launcher and Niri/XWayland window workaround**.

This script is intended for an Arch Linux host running the Niri Wayland
compositor. It is not copied into the Distrobox container and must run from the
Niri host session.

Its purpose is to handle a Niri-specific window problem that can occur after
DaVinci Resolve itself has already been installed correctly inside the
`resolvebox-amd` Distrobox.

The script:

1. verifies that it is running on the Niri host rather than inside Distrobox;
2. verifies that `$DISPLAY` is available for XWayland access;
3. verifies communication with the current Niri session using `niri msg`;
4. uses `flock` to prevent multiple launcher instances;
5. discovers available Distrobox containers;
6. uses Rofi to select a Distrobox when no name is supplied;
7. validates that the selected Distrobox contains `run-davinci` or a Resolve executable;
8. launches Resolve through the selected Distrobox;
9. waits for Resolve's X11 **Project Manager** window;
10. detects the known transient-window condition;
11. removes the `WM_TRANSIENT_FOR` relationship from the affected X11 window;
12. unmaps and remaps the Project Manager window;
13. verifies that Niri now sees the repaired Project Manager;
14. avoids launching another Resolve instance when one is already visible;
15. attempts to repair an already-hidden Project Manager before starting another Resolve process;
16. displays desktop notifications;
17. writes timestamped troubleshooting logs.

The script does **not** install DaVinci Resolve and does not replace `setup.sh` or
`run-davinci`.

See [Niri Wayland Integration](#niri-wayland-integration) for installation,
usage, and troubleshooting.

---

## `system_files/usr/bin/setup-davinci`

Runs **inside the Distrobox container**.

It:

1. verifies that it is running inside the expected container;
2. explains the DaVinci Resolve compatibility workaround;
3. asks the user for confirmation before proceeding;
4. installs the user-provided DaVinci Resolve package;
5. applies the required container compatibility workaround using `patchelf`;
6. applies companion-program compatibility handling where required;
7. optionally creates host launchers.

This script modifies the user's locally installed DaVinci Resolve files as part of the compatibility workaround.

The reason for this and the licensing boundary are explained in the
[DaVinci Resolve Compatibility Workaround](#davinci-resolve-compatibility-workaround) section.

---

## `system_files/usr/bin/run-davinci`

Runs DaVinci Resolve from inside the container.

It:

* verifies that it is running inside Distrobox;
* selects the AMD ROCm OpenCL ICD;
* configures required runtime environment variables;
* exposes configured host paths such as OFX plugins where available;
* configures host DBus access;
* launches DaVinci Resolve using `switcherooctl`.

Normally you do not need to call `/opt/resolve/bin/resolve` directly.

Use:

```bash
run-davinci
```

inside the container instead.

---

## `system_files/usr/bin/list-gpus`

Provides a quick GPU/OpenCL diagnostic.

Inside the container, run:

```bash
list-gpus
```

It checks:

* GPUs visible through `switcheroo-control`
* AMD ROCm OpenCL ICD availability
* OpenCL platforms and devices through `clinfo`, when available

This is useful when troubleshooting GPU detection.

---

## `system_files/usr/bin/add-davinci-launcher`

Creates desktop integration for DaVinci Resolve.

It prepares host-side application launcher entries so programs installed inside the Distrobox can be launched from the normal Linux desktop application menu.

The generated launcher ultimately starts the program through the correct Distrobox container and `run-davinci`.

The launcher is optional.

---

# Quick Start

For users who already understand Distrobox, the complete process is:

```bash
git clone https://github.com/vipinbonline/resolvebox-amd.git 


cd resolvebox-amd
```

Download the DaVinci Resolve Linux `.run` installer from Blackmagic Design and place it in this directory.

Then configure your container HOME in:

```text
resolvebox.ini
```

Make the installer executable:

```bash
chmod +x DaVinci_Resolve_*_Linux.run
```

Run:

```bash
./setup.sh resolvebox.ini resolvebox ./DaVinci_Resolve_21.0.4_Linux.run
```

Read and accept the compatibility-workaround confirmation if you want to continue.

### Niri Users

If the host uses Niri, first complete the normal `resolvebox-amd` installation.

Then install the additional Arch Linux host packages described in
[Additional Requirements for Niri Users](#additional-requirements-for-niri-users),
make the helper executable, and launch Resolve through it:

```bash
chmod +x davinci-resolve-niri

./davinci-resolve-niri resolvebox
```

You may also omit the container name and select a Distrobox through Rofi:

```bash
./davinci-resolve-niri
```

The normal Distrobox installation must exist before using this helper.

---

# Detailed Installation

## Step 1 — Clone the Repository

Clone `resolvebox-amd`:

```bash
git clone https://github.com/<your-github-username>/resolvebox-amd.git
```

Enter the repository:

```bash
cd resolvebox-amd
```

You should now be inside a directory similar to:

```text
resolvebox-amd/
├── Dockerfile
├── resolvebox.ini
├── setup.sh
├── davinci-resolve-niri
├── davinci-dependencies
└── ...
```

All commands shown below assume you are in this directory.

---

# Step 2 — Download DaVinci Resolve

Download the **Linux** version of DaVinci Resolve directly from the official Blackmagic Design website.

Do not download the installer from this repository or from unofficial mirrors.

Blackmagic currently provides DaVinci Resolve for Linux through its official DaVinci Resolve download page.

After downloading and extracting the Blackmagic download if necessary, you should have a Linux installer with a filename similar to:

```text
DaVinci_Resolve_21.0.4_Linux.run
```

or, for Studio:

```text
DaVinci_Resolve_Studio_21.0.4_Linux.run
```

The exact version may be different.

`resolvebox-amd` does not hardcode the Resolve version.

---

# Step 3 — Where Should the Installer Be Kept?

The easiest approach is to copy or move the `.run` installer into the cloned repository directory.

For example:

```text
resolvebox-amd/
├── DaVinci_Resolve_21.0.4_Linux.run
├── Dockerfile
├── resolvebox.ini
├── setup.sh
├── davinci-resolve-niri
├── davinci-dependencies
└── system_files/
```

Then the installation command is simple:

```bash
./setup.sh resolvebox.ini resolvebox ./DaVinci_Resolve_21.0.4_Linux.run
```

The installer **does not technically have to be stored in the repository directory**.

You may keep it somewhere else and provide its full path:

```bash
./setup.sh \
    resolvebox.ini \
    resolvebox \
    /mnt/mydata/installers/DaVinci_Resolve_21.0.4_Linux.run
```

`setup.sh` resolves the installer path before passing it into the container.

> [!WARNING]
> Do not commit the DaVinci Resolve installer to Git.
>
> The installer is proprietary Blackmagic Design software and is not part of `resolvebox-amd`.

Before committing changes, always check:

```bash
git status
```

The DaVinci installer should never appear in a Git commit.

---

# Step 4 — Make the Installer Executable

If required:

```bash
chmod +x DaVinci_Resolve_*_Linux.run
```

For Studio:

```bash
chmod +x DaVinci_Resolve_Studio_*_Linux.run
```

You can confirm:

```bash
ls -lh DaVinci_Resolve*_Linux.run
```

---

# Step 5 — Configure `resolvebox.ini`

Before running the installer, review:

```text
resolvebox.ini
```

The default structure is:

```ini
[resolvebox]

image=localhost/resolvebox-amd:44

pull=false
root=false
init=false
nvidia=false
replace=false
start_now=true
entry=false

home=/absolute/path/to/resolvebox-home
```

---

# Understanding `resolvebox.ini`

## `[resolvebox]`

```ini
[resolvebox]
```

This is the Distrobox Assemble section name.

For this project, the section name is also used as the **container name**.

With:

```ini
[resolvebox]
```

the resulting container is:

```text
resolvebox
```

The installation command therefore uses:

```bash
./setup.sh resolvebox.ini resolvebox ...
```

where the second argument:

```text
resolvebox
```

selects the `[resolvebox]` section and becomes the Distrobox/container name.

---

## `image=`

```ini
image=localhost/resolvebox-amd:44
```

This is the local Podman image used to create the container.

`setup.sh` reads this value and builds the Dockerfile using this value as the Podman image tag.

In other words:

```text
Dockerfile
    ↓
podman build
    ↓
localhost/resolvebox-amd:44
    ↓
Distrobox
```

Normally you do not need to change this value.

The image name and container name are independent.

For example:

```text
Container name: resolvebox
Image name:     localhost/resolvebox-amd:44
```

---

## `pull=false`

```ini
pull=false
```

The image is built locally by `setup.sh`.

For that reason, the configuration uses:

```text
pull=false
```

so Distrobox does not attempt to pull the image from an external container registry.

Do not change this to `true` for the normal `resolvebox-amd` workflow.

---

## `root=false`

```ini
root=false
```

Creates a normal rootless Distrobox.

This is the recommended configuration for this project.

It avoids creating the container as a rootful Podman container.

---

## `init=false`

```ini
init=false
```

The container does not use a separate init/systemd environment.

DaVinci Resolve does not require `resolvebox-amd` to operate as a full system container.

---

## `nvidia=false`

```ini
nvidia=false
```

`resolvebox-amd` is specifically designed for AMD/ROCm.

NVIDIA integration is therefore disabled.

---

## `replace=false`

```ini
replace=false
```

Distrobox Assemble should not automatically replace an already existing container.

Container replacement is deliberately managed by `setup.sh` through the project's:

```text
rebuild
```

and:

```text
remove
```

operations.

---

## `start_now=true`

```ini
start_now=true
```

Starts the container after Distrobox creates it.

`setup.sh` also enters the container once after creation so Distrobox can complete its initial setup.

---

## `entry=false`

```ini
entry=false
```

Disables creation of a generic Distrobox application-menu entry for the container itself.

This is separate from the DaVinci Resolve launcher.

`resolvebox-amd` provides its own Resolve launcher integration through:

```text
add-davinci-launcher
```

---

# Understanding `home=`

The `home=` setting deserves special attention.

Example:

```ini
home=/mnt/mydata/distrobox-home/resolvebox
```

This defines the HOME directory used by the container.

Without a custom Distrobox HOME, container applications may use the normal host HOME and place application configuration and dotfiles there.

Using a separate HOME gives the container its own location for such state.

For example:

```text
Host HOME:

/home/alice

Container HOME:

/mnt/mydata/distrobox-home/resolvebox
```

This is useful for keeping container-specific configuration separate from the normal host HOME.

### Recommended Setup

Create a dedicated directory:

```bash
mkdir -p /mnt/mydata/distrobox-home/resolvebox
```

Then configure:

```ini
home=/mnt/mydata/distrobox-home/resolvebox
```

You can use any suitable absolute path.

For example:

```ini
home=/home/alice/distrobox-homes/resolvebox
```

or:

```ini
home=/mnt/storage/distrobox-home/resolvebox
```

The path should:

* be an absolute host path;
* be writable by your normal user;
* have enough free space for container/application state;
* preferably be outside the cloned Git repository.

> [!NOTE]
> A custom Distrobox `home=` is useful for keeping container configuration and dotfiles separate, but it is **not a security sandbox**.
>
> Distrobox can still expose the normal host HOME and other host resources to the container as part of its host integration.

---

# Why Should `home=` Be Changed?

The repository cannot know where you want container data stored.

Therefore, if the example contains a machine-specific path such as:

```ini
home=/mnt/mydata/...
```

you should replace it with a path that exists on **your own system**.

For example:

```ini
home=/home/alice/distrobox-home/resolvebox
```

Do not blindly copy another user's `/mnt/...` path unless that path exists and is appropriate on your machine.

---

# Changing the Container Name

The default container name is:

```text
resolvebox
```

because the manifest contains:

```ini
[resolvebox]
```

and the command uses:

```bash
./setup.sh resolvebox.ini resolvebox ...
```

You can use another name.

For example, suppose you want:

```text
davinci-amd
```

Change:

```ini
[resolvebox]
```

to:

```ini
[davinci-amd]
```

I also recommend changing the custom HOME directory:

```ini
home=/mnt/mydata/distrobox-home/davinci-amd
```

The complete configuration becomes:

```ini
[davinci-amd]

image=localhost/resolvebox-amd:44

pull=false
root=false
init=false
nvidia=false
replace=false
start_now=true
entry=false

home=/mnt/mydata/distrobox-home/davinci-amd
```

Create the new HOME:

```bash
mkdir -p /mnt/mydata/distrobox-home/davinci-amd
```

Then run:

```bash
./setup.sh \
    resolvebox.ini \
    davinci-amd \
    ./DaVinci_Resolve_21.0.4_Linux.run
```

Notice that the second argument changed from:

```text
resolvebox
```

to:

```text
davinci-amd
```

because it must select the corresponding INI section.

---

# Does the INI Filename Have to Match the Container Name?

For clarity, this repository uses:

```text
resolvebox.ini
    ↓
[resolvebox]
    ↓
resolvebox container
```

Keeping these names aligned makes the configuration easier to understand.

However, the important relationship used by `setup.sh` is:

```text
second command argument
        ↓
INI section name
        ↓
Distrobox container name
```

For example:

```bash
./setup.sh resolvebox.ini davinci-amd ...
```

expects:

```ini
[davinci-amd]
```

inside `resolvebox.ini`.

You may also rename the INI file if you prefer:

```text
davinci-amd.ini
```

and then use:

```bash
./setup.sh \
    davinci-amd.ini \
    davinci-amd \
    ./DaVinci_Resolve_21.0.4_Linux.run
```

Using the same filename, section name, HOME directory name, and container name is recommended because it avoids confusion.

For example:

```text
davinci-amd.ini

[davinci-amd]

home=/mnt/mydata/distrobox-home/davinci-amd

Container:
davinci-amd
```

---

# `volume=` — Optional Host Directories

You can optionally mount additional host directories into the container.

Example:

```ini
volume=/mnt/mydata/video:/mnt/video:rw
```

This means:

```text
Host:

/mnt/mydata/video

        ↓

Container:

/mnt/video
```

with read/write access.

This can be useful for video media stored outside your normal HOME.

For example:

```ini
volume=/mnt/media/projects:/mnt/projects:rw
```

Then DaVinci Resolve inside the container can access:

```text
/mnt/projects
```

Do not add a volume unless you need it.

---

# Step 6 — Review the Configuration

Before installation, check:

```bash
cat resolvebox.ini
```

At minimum verify:

```text
[section name]
image=
home=
```

Make sure the HOME directory exists:

```bash
ls -ld /path/to/your/resolvebox-home
```

You can also confirm that the installer exists:

```bash
ls -lh ./DaVinci_Resolve*_Linux.run
```

---

# Step 7 — Start Installation

Using the default configuration:

```bash
./setup.sh \
    resolvebox.ini \
    resolvebox \
    ./DaVinci_Resolve_21.0.4_Linux.run
```

The arguments mean:

```text
./setup.sh
    │
    ├── resolvebox.ini
    │      Distrobox Assemble configuration
    │
    ├── resolvebox
    │      INI section + container name
    │
    └── ./DaVinci_Resolve_21.0.4_Linux.run
           user-provided installer
```

---

# What Happens During Installation?

The setup process:

1. validates the required host commands;
2. reads the selected INI section;
3. reads the local image name;
4. builds the Podman image from `Dockerfile`;
5. creates the selected Distrobox using Distrobox Assemble;
6. starts/initializes the container;
7. extracts the user-provided DaVinci Resolve installer into a temporary directory;
8. exposes the extracted installer to the container;
9. starts `setup-davinci` inside the container;
10. explains the required DaVinci Resolve compatibility workaround;
11. asks the user whether to continue;
12. installs DaVinci Resolve;
13. applies the selected compatibility handling;
14. optionally creates host launchers;
15. removes temporary installer extraction files when setup exits.

The original `.run` file remains where the user placed it.

---

# Important: Compatibility Workaround Confirmation

During installation, `resolvebox-amd` displays a confirmation before installing and configuring DaVinci Resolve.

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
> For the currently supported `resolvebox-amd` environment, this compatibility step is considered part of the working installation.
>
> If you answer `n` or press Enter without answering `y`, the setup stops before DaVinci Resolve is installed.
>
> This is intentional. Installing Resolve while skipping a compatibility step required by this environment could leave the user with an installation that does not start correctly.

If you understand the modification and want to continue, answer:

```text
y
```

or:

```text
yes
```

---

# Why Is This Confirmation Required?

There are two separately licensed pieces of software involved:

```text
resolvebox-amd
        │
        └── Apache License 2.0

DaVinci Resolve
        │
        └── Blackmagic Design license
```

`resolvebox-amd` can license its own source code and applicable upstream Apache-licensed material.

It cannot grant additional rights to DaVinci Resolve.

The compatibility workaround changes files in the user's separately obtained DaVinci Resolve installation.

For that reason, the project explicitly tells the user about the modification before performing it.

The confirmation:

* makes the modification visible;
* explains why it is necessary;
* gives the user the opportunity to stop;
* does not accept Blackmagic Design's license on the user's behalf;
* does not replace Blackmagic Design's license;
* does not grant additional rights to DaVinci Resolve.

Users remain responsible for reviewing and complying with the license terms applicable to their copy of DaVinci Resolve.

---

# DaVinci Resolve Compatibility Workaround

## Why Is the Workaround Needed?

DaVinci Resolve is built for particular Linux runtime environments.

The libraries available in the Fedora/Distrobox environment used by `resolvebox-amd` can differ from the environment expected by DaVinci Resolve.

Without additional compatibility handling, DaVinci Resolve may fail to start or some components may not operate correctly.

`resolvebox-amd` therefore uses `patchelf` to add required system libraries to the ELF dynamic dependency metadata of the user's locally installed DaVinci Resolve executables.

The current workaround uses libraries including:

```text
libglib-2.0.so.0
libgdk_pixbuf-2.0.so.0
libgio-2.0.so.0
libgmodule-2.0.so.0
```

---

## What the Workaround Does

The workaround:

* operates only on a DaVinci Resolve installation supplied and installed by the user;
* modifies ELF dependency metadata in the user's local DaVinci Resolve installation;
* does not distribute modified DaVinci Resolve binaries;
* does not distribute the DaVinci Resolve installer;
* does not provide or bypass DaVinci Resolve Studio activation;
* does not remove or interfere with Resolve licensing mechanisms;
* exists solely as a Linux/container runtime compatibility workaround;
* is not represented as an official Blackmagic-supported modification.

The setup may also apply compatibility handling to certain DaVinci Resolve companion-program components when required by the container environment.

---

## Licensing Boundary

DaVinci Resolve remains proprietary software from Blackmagic Design Pty Ltd.

The Apache License 2.0 covering `resolvebox-amd` applies only to:

* `resolvebox-amd` source code;
* original contributions to this project;
* applicable Apache-licensed upstream `davincibox` material.

It does not grant permission to modify, redistribute, sublicense, or otherwise use DaVinci Resolve beyond rights provided by Blackmagic Design or applicable law.

Where a reliable non-modifying runtime solution is available, `resolvebox-amd` should prefer that approach over modifying DaVinci Resolve binaries.

---

# Launcher Installation

After Resolve setup and compatibility configuration, the installer may ask:

```text
Add DaVinci Resolve launcher? [Y/n]
```

Pressing Enter or answering:

```text
y
```

creates the host desktop integration.

Answering:

```text
n
```

skips it.

A launcher can later be created from inside the container using:

```bash
add-davinci-launcher
```

---

# Running DaVinci Resolve

If launcher integration was enabled, launch DaVinci Resolve normally from your desktop application menu.

Alternatively, enter the container:

```bash
distrobox enter resolvebox
```

Then run:

```bash
run-davinci
```

If you changed the container name:

```bash
distrobox enter davinci-amd
```

and then:

```bash
run-davinci
```

## Niri Users

If your host is running Niri and you encounter the Project Manager window issue
described below, prefer the host-side helper:

```bash
./davinci-resolve-niri resolvebox
```

or, after installing it into your user `PATH`:

```bash
davinci-resolve-niri resolvebox
```

The helper still launches Resolve through the normal `run-davinci` workflow, but
it additionally detects and repairs the affected Project Manager X11 window.

---

# Niri Wayland Integration

## Scope

This section applies only when the **host operating system is running Niri**.

The normal `resolvebox-amd` setup is still responsible for:

```text
Podman image
    ↓
Distrobox
    ↓
DaVinci Resolve installation
    ↓
AMD/ROCm OpenCL setup
    ↓
run-davinci
```

The optional Niri helper adds host-side window handling:

```text
run-davinci
    ↓
DaVinci Resolve (Qt xcb / X11)
    ↓
XWayland
    ↓
xwayland-satellite
    ↓
davinci-resolve-niri
    ↓
Niri
```

This Niri workaround is separate from the `patchelf` compatibility workaround
used during Resolve installation.

The two workarounds address different problems:

| Workaround | Runs where? | Problem addressed |
|---|---|---|
| `patchelf` compatibility setup | Inside the Resolve Distrobox | Runtime-library compatibility needed for Resolve to operate in the container |
| `davinci-resolve-niri` | On the Niri host | Project Manager X11 window not becoming visible correctly through XWayland/xwayland-satellite |

Non-Niri users can ignore `davinci-resolve-niri` completely.

---

## Why Is a Niri Workaround Needed?

DaVinci Resolve is launched with the Qt X11 backend:

```text
QT_QPA_PLATFORM=xcb
```

In the affected state, Resolve creates its **Project Manager** as a
transient/modal X11 child associated with a hidden Qt owner window.

The X11 window can exist, while `xwayland-satellite`/Niri may not expose it as
the expected visible Wayland toplevel.

The result can look like this:

```text
Resolve process starts
        │
        ▼
Project Manager X11 window exists
        │
        ▼
WM_TRANSIENT_FOR points to a hidden owner window
        │
        ▼
xwayland-satellite / Niri does not expose the Project Manager
as the expected visible toplevel
        │
        ▼
Resolve appears to start, but no Project Manager is visible
```

`davinci-resolve-niri` detects this state and performs a targeted window repair:

```text
Find Resolve "Project Manager"
        │
        ▼
Inspect X11 window properties
        │
        ▼
Remove WM_TRANSIENT_FOR
        │
        ▼
Unmap the X11 window
        │
        ▼
Map the X11 window again
        │
        ▼
Verify with `niri msg windows`
        │
        ▼
Project Manager becomes visible in Niri
```

The helper changes the **live X11 window state**. It does not patch Niri,
`xwayland-satellite`, or XWayland.

---

## Niri Prerequisites on Arch Linux

Install the required host-side packages:

```bash
sudo pacman -S --needed \
    niri \
    xwayland-satellite \
    xorg-xwayland \
    rofi \
    xorg-xwininfo \
    xorg-xprop \
    xdotool \
    libnotify \
    util-linux \
    gawk
```

Also make sure Distrobox is installed:

```bash
sudo pacman -S --needed distrobox
```

The helper requires these commands:

```bash
command -v distrobox
command -v rofi
command -v xwininfo
command -v xprop
command -v xdotool
command -v niri
command -v flock
command -v awk
command -v notify-send
```

---

## Verify Niri / XWayland Before Using the Helper

Run these commands from a terminal opened **inside the Niri session**.

Check Niri IPC:

```bash
niri msg windows
```

The command should return information about Niri-managed windows.

Check that `xwayland-satellite` and XWayland are installed:

```bash
command -v xwayland-satellite
command -v Xwayland
```

Check `DISPLAY`:

```bash
printf 'DISPLAY=%s\n' "${DISPLAY:-<not set>}"
```

When Niri's XWayland integration is active, `DISPLAY` should have a value such as:

```text
DISPLAY=:0
```

The actual display number can be different.

> [!IMPORTANT]
> `davinci-resolve-niri` intentionally refuses to run if `$DISPLAY` is empty,
> because the script needs access to the host XWayland session.
>
> It also refuses to run if `niri msg windows` cannot communicate with the
> current Niri session.

For Niri 25.08 and newer, Niri can manage `xwayland-satellite` automatically.
A current Arch Linux setup should normally not need a manually started
`xwayland-satellite` process or a manually configured `$DISPLAY`.

---

## Make `davinci-resolve-niri` Executable

From the cloned repository:

```bash
chmod +x davinci-resolve-niri
```

The script must be run on the **host**.

Do **not** run:

```bash
distrobox enter resolvebox
./davinci-resolve-niri
```

The helper needs direct access to the host Niri and XWayland session and will
reject execution from inside a container.

---

## Run the Niri Helper With a Container Name

After the normal `resolvebox-amd` installation is complete:

```bash
./davinci-resolve-niri resolvebox
```

Here:

```text
resolvebox
```

is the Distrobox name.

If your INI section/container is:

```ini
[davinci-amd]
```

use:

```bash
./davinci-resolve-niri davinci-amd
```

The script verifies that the requested Distrobox exists and checks that it
contains either:

```text
run-davinci
```

or:

```text
/opt/resolve/bin/resolve
```

before trying to start Resolve.

---

## Select the Resolve Distrobox With Rofi

If you omit the container name:

```bash
./davinci-resolve-niri
```

the script obtains the current Distrobox list and presents it through Rofi.

Select the container containing DaVinci Resolve.

The Rofi menu shows information obtained from:

```bash
distrobox list
```

and the script validates the selected container before launching.

> [!NOTE]
> In the current implementation, `rofi` is checked as a required command even
> when a Distrobox name is supplied directly.

---

## Install the Niri Helper Into Your User PATH

To run the helper without staying inside the cloned repository:

```bash
mkdir -p "$HOME/.local/bin"

install -Dm755 \
    davinci-resolve-niri \
    "$HOME/.local/bin/davinci-resolve-niri"
```

Verify:

```bash
command -v davinci-resolve-niri
```

If the command is not found, make sure:

```text
$HOME/.local/bin
```

is included in your `PATH`.

You can then run:

```bash
davinci-resolve-niri resolvebox
```

or:

```bash
davinci-resolve-niri
```

for Rofi selection.

---

## Optional Desktop Application Entry for Niri

If you want a dedicated application-menu entry that always uses the Niri helper,
first install `davinci-resolve-niri` into `~/.local/bin` as shown above.

Then create:

```bash
mkdir -p "$HOME/.local/share/applications"

cat > "$HOME/.local/share/applications/resolvebox-niri.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=DaVinci Resolve (resolvebox / Niri)
Comment=Launch DaVinci Resolve through resolvebox with the Niri window workaround
Exec=$HOME/.local/bin/davinci-resolve-niri resolvebox
Terminal=false
StartupNotify=true
StartupWMClass=resolve
Icon=video-x-generic
EOF
```

If your container has a different name, replace:

```text
resolvebox
```

in the `Exec=` line with your actual Distrobox name.

This entry intentionally uses a generic video icon rather than requiring
Blackmagic Design artwork.

> [!NOTE]
> The normal launcher created during Resolve setup starts the container-side
> `run-davinci` command. On a Niri host affected by the Project Manager issue,
> this dedicated Niri entry is preferable because it runs the additional
> host-side window repair.

---

## Recommended Launch Method on Niri

For a known container name, the recommended Niri command is:

```bash
davinci-resolve-niri resolvebox
```

This gives the helper a deterministic container and avoids the Rofi selection
step, while still performing all Niri/X11 checks and window repair logic.

If you have several Resolve test containers and want to choose interactively:

```bash
davinci-resolve-niri
```

uses Rofi.

Launching directly with:

```bash
distrobox enter resolvebox -- run-davinci
```

still starts Resolve, but it does **not** perform the Project Manager window
repair.

---

## Existing Resolve Instances

The Niri helper tries to avoid duplicate Resolve launches.

Before starting a new instance, it checks whether Niri already has a Resolve
window.

If Resolve is already visible:

```text
Resolve already has a visible window in Niri.
```

the helper exits instead of launching another copy.

It also searches the X11 window tree for an already-existing hidden Project
Manager.

If it finds one, it tries to repair that existing window first instead of
starting a second Resolve process.

---

## Window Repair Attempts and Timeout

The current helper waits up to:

```text
60 seconds
```

for the Resolve Project Manager to appear.

When the affected Project Manager is found, the helper can retry the
unmap/remap repair up to:

```text
3 attempts
```

After each repair, it checks `niri msg windows` to confirm that Niri can see the
Project Manager.

If the repair cannot be confirmed, the helper exits with an error and points to
the log file.

---

## Niri Launcher Logs

Logs are stored on the **host**, not inside the Resolve Distrobox.

Default state directory:

```text
~/.local/state/davinci-resolve-launcher/
```

If `XDG_STATE_HOME` is set, that location is used instead.

Each execution creates a timestamped log similar to:

```text
resolve-20260829-221500.log
```

The latest log is available through:

```text
~/.local/state/davinci-resolve-launcher/latest.log
```

View it with:

```bash
less ~/.local/state/davinci-resolve-launcher/latest.log
```

or:

```bash
cat ~/.local/state/davinci-resolve-launcher/latest.log
```

The log records launcher activity and X11 window properties useful when
troubleshooting the Project Manager.

---

## Niri Launcher Lock

The script uses `flock` to prevent multiple launcher processes from running at
the same time.

The lock file is created under:

```text
$XDG_RUNTIME_DIR
```

or `/tmp` when `XDG_RUNTIME_DIR` is unavailable.

This lock controls concurrent **launcher script instances**.

The helper separately checks Niri/X11 state to avoid launching another Resolve
when an existing Resolve window or hidden Project Manager is already present.

---

## Niri Troubleshooting

### `DISPLAY is not set`

If the launcher reports:

```text
DISPLAY is not set. XWayland is not available to this launcher.
```

check:

```bash
printf 'DISPLAY=%s\n' "${DISPLAY:-<not set>}"
command -v xwayland-satellite
command -v Xwayland
```

Run the helper from a terminal belonging to the active Niri session.

On a current Niri setup, also make sure you have not disabled Niri's
`xwayland-satellite` integration.

---

### `Unable to communicate with the current Niri session`

Test:

```bash
niri msg windows
```

If this fails, the helper cannot query or verify Niri windows.

Run it from the same user/session that owns the active Niri compositor.

---

### `No Distrobox containers were found`

Check:

```bash
distrobox list
```

Complete the normal `resolvebox-amd` installation first if the Resolve container
does not exist.

---

### `DaVinci Resolve was not found in Distrobox`

For the default container:

```bash
distrobox enter resolvebox
```

Then check:

```bash
command -v run-davinci
```

and:

```bash
test -x /opt/resolve/bin/resolve && echo "Resolve installed"
```

If both checks fail, install Resolve using the normal `setup.sh` workflow before
using the Niri helper.

---

### Project Manager Times Out

Inspect the latest host-side log:

```bash
less ~/.local/state/davinci-resolve-launcher/latest.log
```

Check whether the Project Manager exists in the X11 tree:

```bash
xwininfo -root -tree | grep -i -E 'resolve|Project Manager'
```

Check whether Niri sees Resolve:

```bash
niri msg windows
```

The helper itself waits for the Project Manager, performs the window repair, and
then verifies the result through Niri IPC.

---

### Rofi Does Not Open

Verify:

```bash
command -v rofi
```

and install it on Arch Linux if necessary:

```bash
sudo pacman -S --needed rofi
```

You can still provide the intended container explicitly:

```bash
davinci-resolve-niri resolvebox
```

However, the current script performs a startup dependency check for `rofi`, so
the package must still be installed.

---

## What the Niri Helper Does Not Do

`davinci-resolve-niri` does **not**:

* install DaVinci Resolve;
* replace the normal `setup.sh` workflow;
* replace `run-davinci`;
* modify the Niri configuration;
* patch Niri;
* patch `xwayland-satellite`;
* patch XWayland;
* change DaVinci Resolve licensing or activation;
* replace the container compatibility workaround performed during installation.

It is a host-side launcher and live X11 window-management workaround for the
specific Resolve Project Manager behavior observed with Niri and
`xwayland-satellite`.

---

# Checking the GPU

Enter the container:

```bash
distrobox enter resolvebox
```

Run:

```bash
list-gpus
```

Example checks performed include:

```text
Distrobox container
AMD ROCm OpenCL ICD
switcheroo-control GPU list
OpenCL platforms/devices
```

You can also manually run:

```bash
clinfo -l
```

when `clinfo` is available.

---

# Checking the Container

From the host:

```bash
distrobox list
```

You should see an entry similar to:

```text
NAME        STATUS        IMAGE
resolvebox  Up            localhost/resolvebox-amd:44
```

Podman can also show the locally built image:

```bash
podman images
```

---

# Rebuild

Use rebuild when you want to:

* remove the existing managed container;
* rebuild the local image from the current repository files;
* recreate the container;
* reinstall DaVinci Resolve.

Run:

```bash
./setup.sh \
    resolvebox.ini \
    resolvebox \
    rebuild \
    ./DaVinci_Resolve_21.0.4_Linux.run
```

If using a custom container:

```bash
./setup.sh \
    davinci-amd.ini \
    davinci-amd \
    rebuild \
    ./DaVinci_Resolve_21.0.4_Linux.run
```

> [!IMPORTANT]
> Rebuilding the container is different from simply updating packages inside an existing container.
>
> The `rebuild` workflow recreates the managed environment from the repository configuration.

---

# Remove

To remove the managed container:

```bash
./setup.sh resolvebox.ini resolvebox remove
```

The setup script first attempts to remove launcher integration created for the container and then removes the Distrobox.

For a custom container name:

```bash
./setup.sh davinci-amd.ini davinci-amd remove
```

---

# Changing the Container Name Later

Suppose you already have:

```text
resolvebox
```

and want a new container:

```text
resolvebox-test
```

Create/change the section:

```ini
[resolvebox-test]

image=localhost/resolvebox-amd:44

pull=false
root=false
init=false
nvidia=false
replace=false
start_now=true
entry=false

home=/mnt/mydata/distrobox-home/resolvebox-test
```

Create the HOME:

```bash
mkdir -p /mnt/mydata/distrobox-home/resolvebox-test
```

Then:

```bash
./setup.sh \
    resolvebox.ini \
    resolvebox-test \
    ./DaVinci_Resolve_21.0.4_Linux.run
```

This creates a **different Distrobox**.

Changing the name does not rename an already existing container.

---

# Common Mistakes

## Section Name and Command Name Do Not Match

Wrong:

```ini
[resolvebox]
```

with:

```bash
./setup.sh resolvebox.ini davinci-amd installer.run
```

The script looks for:

```ini
[davinci-amd]
```

and will fail because it does not exist.

Correct:

```ini
[davinci-amd]
```

with:

```bash
./setup.sh resolvebox.ini davinci-amd installer.run
```

---

## Using `pull=true`

Do not use:

```ini
pull=true
```

for the normal project configuration.

The image is built locally by `setup.sh`.

Use:

```ini
pull=false
```

---

## Using an Invalid `home=` Path

Do not copy another person's path blindly:

```ini
home=/mnt/mydata/someone-elses-layout/resolvebox
```

Choose a path appropriate for your machine.

Example:

```bash
mkdir -p "$HOME/distrobox-homes/resolvebox"
```

and:

```ini
home=/home/your-user/distrobox-homes/resolvebox
```

Use the actual absolute path rather than `$HOME` inside the INI if your configuration expects an absolute path.

---

## Accidentally Skipping the Compatibility Confirmation

The prompt defaults to:

```text
[y/N]
```

Pressing Enter therefore means:

```text
No
```

and the installation stops.

To proceed, explicitly type:

```text
y
```

or:

```text
yes
```

This behavior is intentional because the project does not silently modify the user's DaVinci Resolve installation.

---

## Committing the DaVinci Installer

Never run:

```bash
git add DaVinci_Resolve_21.0.4_Linux.run
```

The installer is not part of this project.

Check:

```bash
git status
```

before pushing changes.

---

# Updating `resolvebox-amd`

To obtain newer project source:

```bash
git pull
```

If you modified `resolvebox.ini` locally, review your changes before pulling because Git may need to merge the local configuration with upstream changes.

Changes to container-side files such as:

```text
Dockerfile
davinci-dependencies
system_files/
```

require the project's rebuild workflow so the local container image is recreated:

```bash
./setup.sh \
    resolvebox.ini \
    resolvebox \
    rebuild \
    ./DaVinci_Resolve_21.0.4_Linux.run
```

Changes only to the host-side:

```text
davinci-resolve-niri
```

do **not** require rebuilding the Distrobox image.

If you installed a copy of the helper into `~/.local/bin`, reinstall the updated
script after pulling repository changes:

```bash
install -Dm755 \
    davinci-resolve-niri \
    "$HOME/.local/bin/davinci-resolve-niri"
```

---

# Project Origin

`resolvebox-amd` is derived from:

**davincibox**
https://github.com/zelikos/davincibox

The original development base for this project was davincibox commit:

```text
d6b5f768200a2e67f01f961e3de82e40f712a5b6
```

Permanent upstream commit reference:

https://github.com/zelikos/davincibox/commit/d6b5f768200a2e67f01f961e3de82e40f712a5b6

davincibox is distributed under the Apache License, Version 2.0.

This project contains substantial modifications related to:

* AMD/ROCm support
* container image construction
* Distrobox configuration
* local Podman builds
* installation workflow
* configurable container naming
* launcher integration
* GPU/OpenCL diagnostics
* runtime tooling
* optional Arch Linux/Niri host integration
* Niri/XWayland Project Manager window workaround

The original davincibox project and its contributors retain copyright in their respective contributions.

See `ATTRIBUTION.md` for detailed project provenance and upstream acknowledgements.

---

# DaVinci Resolve and Proprietary Software

DaVinci Resolve is proprietary software developed by Blackmagic Design Pty Ltd.

DaVinci Resolve is **not distributed as part of this project**.

Users must obtain the installer separately from Blackmagic Design and are responsible for complying with the license terms applicable to their copy of DaVinci Resolve.

The Apache License 2.0 covering `resolvebox-amd` does not grant rights to:

* DaVinci Resolve
* Blackmagic Design software
* Blackmagic Design trademarks
* Blackmagic Design graphics or other proprietary assets

This project provides independently maintained container, installation, compatibility, and integration tooling.

---

# Third-Party Software

The container built by this project uses third-party software and packages, including components from:

* Fedora
* Distrobox
* Podman
* AMD ROCm
* OpenCL implementations
* system libraries
* Niri, when using the optional Niri helper
* XWayland and `xwayland-satellite`, when using Niri/X11 integration
* Rofi and X11 utilities used by the optional Niri helper
* other runtime dependencies

These components remain subject to their respective licenses.

The Apache License 2.0 covering this repository does not relicense third-party packages installed into the container.

If prebuilt container images are distributed, the included third-party software should be reviewed separately for applicable redistribution and licensing requirements.

---

# License

`resolvebox-amd` is distributed under the **Apache License, Version 2.0**.

Portions of this project are derived from `zelikos/davincibox`, which is also distributed under Apache License 2.0.

Copyright in the original davincibox contributions remains with the respective original copyright holders and contributors.

Copyright 2026 Vipin Balakrishnan applies only to modifications and original contributions made as part of `resolvebox-amd`.

See:

```text
LICENSE
```

for the complete Apache License 2.0 terms.

---

# Attribution

Detailed upstream attribution, provenance, and acknowledgements are maintained in:

```text
ATTRIBUTION.md
```

The repository also contains:

```text
NOTICE
```

for concise project attribution information.

---

# Niri Helper Licensing Scope

`davinci-resolve-niri` is source code distributed as part of this project under
the project's Apache License 2.0 terms.

Niri, XWayland, `xwayland-satellite`, Rofi, and the other external commands used
by the helper are separate third-party programs and remain subject to their own
licenses.

The helper invokes those programs; this project does not relicense them.

---

# Trademarks and Disclaimer

DaVinci Resolve and Blackmagic Design are trademarks or product names of their respective owners.

AMD, AMD ROCm, and related AMD product names are trademarks or product names of Advanced Micro Devices, Inc.

`resolvebox-amd` is an independent community project.

It is not affiliated with, sponsored by, certified by, approved by, or endorsed by:

* Blackmagic Design Pty Ltd.
* Advanced Micro Devices, Inc.
* the Fedora Project or Red Hat
* Distrobox
* Podman
* the upstream davincibox project

References to those projects, products, technologies, and companies are for identification, compatibility, documentation, and attribution purposes only.
