# Posit justfile

## Quick start

```bash
# Install just
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin

# Download the justfile
curl -O https://raw.githubusercontent.com/SamEdwardes/posit-justfile/main/justfile

# Run init
just init

# Install the required tools
just install-workbench
```

## Examples

See all of the available commands:

```bash
just
```

Install the prerequisites:

```bash
just init
```

Install Workbench:

```bash
just install-workbench
```

Install a specific version of Workbench:

```bash
just WORKBENCH_INSTALLER='https://s3.amazonaws.com/rstudio-ide-build/electron/jammy/amd64/rstudio-2022.12.0-353-amd64.deb' install-workbench


