# GS4PB AI Version — Running Instructions

GS4PB with integrated AI assistant (Claude-powered genomic selection advisor).  
Image: `umnlorenzgroup/gs4pb:ai-latest` on Docker Hub.

---

## Prerequisites

### API Key
You need an Anthropic API key to use the AI assistant.  
Get one at: https://console.anthropic.com → API Keys

### Local (Docker)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running

### HPC (Singularity/Apptainer)
- Apptainer or Singularity available (`module load apptainer` or similar)
- ~6 GB free disk space for the `.sif` image

---

## Option A — Local (Docker Desktop)

### 1. Pull the image
```bash
docker pull umnlorenzgroup/gs4pb:ai-latest
```

### 2. Create your API key file
Create a file called `.env` in a safe location (e.g. your home directory).  
**Never commit this file to git.**

```
ANTHROPIC_API_KEY=sk-ant-...
```

### 3. Run
```bash
docker run --env-file /path/to/.env \
  --mount type=bind,source=/path/to/your/results,target=/root/Results \
  -p 8080:8080 \
  umnlorenzgroup/gs4pb:ai-latest
```

Replace `/path/to/your/results` with a local folder where you want output files saved.

### 4. Open the app
Navigate to **http://localhost:8080** in your browser.

---

### Windows example (Git Bash / PowerShell)

```bash
# Git Bash
docker run --env-file "$HOME/.env" \
  --mount type=bind,source="$HOME/Downloads",target=/root/Results \
  -p 8080:8080 \
  umnlorenzgroup/gs4pb:ai-latest
```

```powershell
# PowerShell
docker run --env-file "$env:USERPROFILE\.env" `
  --mount type=bind,source="$env:USERPROFILE\Downloads",target=/root/Results `
  -p 8080:8080 `
  umnlorenzgroup/gs4pb:ai-latest
```

---

## Option B — HPC (Singularity/Apptainer)

### 1. Clone this repo on the HPC
```bash
git clone https://github.com/UMN-Lorenz-Group/GS4PBAppHPCHelp.git
cd GS4PBAppHPCHelp
```

### 2. Pull the Singularity image
```bash
singularity pull --disable-cache gs4pb_ai.sif docker://umnlorenzgroup/gs4pb:ai-latest
```
> This downloads ~4.4 GB. Run from a compute node or in a tmux/screen session.  
> Place `gs4pb_ai.sif` inside the `ai/` folder (it is git-ignored).

### 3. Add your API key
```bash
echo "ANTHROPIC_API_KEY=sk-ant-..." > ai/env/.env
chmod 600 ai/env/.env
```
The `ai/env/` folder is git-ignored — your key will never be committed.

### 4. (Optional) Edit configuration
Edit `ai/config_ai.env` to change the port or other settings:

| Variable   | Default           | Description                     |
|------------|-------------------|---------------------------------|
| `SIF_IMAGE`| `gs4pb_ai.sif`    | Path to the Singularity image   |
| `APP`      | `/srv/shiny-server` | App path inside container     |
| `PORT`     | `8080`            | Port to expose                  |
| `HOST`     | `0.0.0.0`         | Bind address                    |

### 5. Run
```bash
chmod +x ai/run_app_ai.sh
bash ai/run_app_ai.sh
```

The launcher will print the URL when ready:
```
=============================================
  GS4PB Shiny App (AI Version)
  Runtime  : apptainer
  Image    : gs4pb_ai.sif
  App      : /srv/shiny-server
  URL      : http://localhost:8080
  API key  : sk-ant-api03-...
=============================================
```

### 6. Access the app

**If running on a login node or interactive session:**  
Open **http://localhost:8080** in your browser (with SSH port forwarding if remote).

**SSH port forwarding (from your laptop):**
```bash
ssh -L 8080:localhost:8080 username@hpc.hostname.edu
```
Then open **http://localhost:8080** locally.

**If submitting as a job (SLURM example):**
```bash
#!/bin/bash
#SBATCH --job-name=gs4pb-ai
#SBATCH --time=08:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4

cd /path/to/GS4PBAppHPCHelp
bash ai/run_app_ai.sh
```

---

## Runtime directories

The script auto-creates an `ai/runtime/` folder:

```
ai/runtime/
├── r-home/     # Isolated container $HOME
├── r-tmp/      # Container /tmp
└── results/    # Mapped to /root/Results inside the container
                # — app output files (logs, downloads) appear here
```

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `ERROR: API key file not found` | Create `ai/env/.env` with your `ANTHROPIC_API_KEY` |
| `Error communicating with Claude: HTTP 401` | API key invalid or expired — check console.anthropic.com |
| `ERROR: Container image not found` | Run the `singularity pull` step again |
| VCF upload fails silently | Check `ai/runtime/results/GS4PB_App_log-*.txt` for errors |
| Port 8080 already in use | Edit `PORT` in `ai/config_ai.env` |
| `command not found: apptainer` | Load the module: `module load apptainer` |
| App loads but AI chat is missing | Ensure `ANTHROPIC_API_KEY` is set correctly in `ai/env/.env` |

---

## Updating the image

When a new version is released:
```bash
singularity pull --force --disable-cache gs4pb_ai.sif docker://umnlorenzgroup/gs4pb:ai-latest
```

---

## Data privacy

- Phenotype and genotype data you upload stay **inside the container** and are not sent to Anthropic.
- Only the **text messages** you type in the AI chat are sent to the Anthropic API.
- Your API key is read from `ai/env/.env` at runtime and never stored in the image.

See `GS4PB_AI_SystemPrompt_DataPrivacy.md` in the main repository for the full data privacy policy.
