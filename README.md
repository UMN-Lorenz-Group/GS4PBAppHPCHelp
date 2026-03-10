# GS4PB Shiny App — Singularity/Apptainer Launcher

Runs a containerized R Shiny app using a `.sif` image with a single command.

## Requirements

- [Apptainer](https://apptainer.org/docs/user/latest/) or [Singularity](https://docs.sylabs.io/) installed
- The `gs4pb_updated.sif` container image (see [Obtaining the Image](#obtaining-the-image))

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/GS4PBDockerTst.git
cd GS4PBDockerTst

# 2. Place (or symlink) your .sif image here
cp /path/to/gs4pb_updated.sif .

# 3. Make the launcher executable (one-time)
chmod +x run_app.sh

# 4. Run
./run_app.sh
```

Then open **http://localhost:3838** in your browser.

---

## Configuration

Edit `config.env` before running to customise paths and port:

| Variable   | Default                                      | Description                        |
|------------|----------------------------------------------|------------------------------------|
| `SIF_IMAGE`| `gs4pb_updated.sif`                          | Path to the Singularity image      |
| `APP`      | `/srv/shiny-server/App`                      | Shiny app path inside container    |
| `LIB`      | `/srv/shiny-server/App/renv/library/...`     | R library path inside container    |
| `PORT`     | `3838`                                       | Host port to expose                |
| `HOST`     | `0.0.0.0`                                    | Bind address (`127.0.0.1` = local) |

You can also point to an alternate config file:

```bash
./run_app.sh --config /path/to/my_custom.env
```

---

## Runtime directories

The script auto-creates a `runtime/` folder next to `run_app.sh`:

```
runtime/
├── r-home/     # Container $HOME (isolated)
├── r-tmp/      # Container /tmp
└── results/    # Mapped to /root/Results inside the container
```

---

## Obtaining the Image

> *(Replace this section with your actual distribution method.)*

Option A — pull from a registry:
```bash
singularity pull gs4pb_updated.sif oras://ghcr.io/YOUR_ORG/gs4pb:latest
```

Option B — build locally:
```bash
singularity build gs4pb_updated.sif gs4pb.def
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `command not found: singularity` | Install Apptainer or add Singularity to PATH |
| `image not found` | Check `SIF_IMAGE` in `config.env` |
| Port already in use | Change `PORT` in `config.env` |
| Permission denied on `run_app.sh` | Run `chmod +x run_app.sh` |

---

## .gitignore recommendation

Add to your `.gitignore` to avoid committing large/runtime files:

```
*.sif
runtime/
```
