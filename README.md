# Posit justfile

## Installation

Install `just` [docs](https://github.com/casey/just#installation):

With `sudo`:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
```

No `sudo`:

```bash
mkdir -p $HOME/.local/bin
export PATH="$PATH:$HOME/.local/bin"
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to $HOME/.local/bin
```

Download the justfile:

```bash
curl -O xxx
```

docker run --platform "linux/amd64" -it --rm -v $(pwd):/app ubuntu /bin/bash
docker run --platform "linux/amd64" -it --rm -v $(pwd):/app redhat/ubi8 /bin/bash


## TMP

```bash
apt-get update && apt-get install -y curl && curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin && cd app
```