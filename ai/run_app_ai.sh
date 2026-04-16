#!/usr/bin/env bash
# =============================================================
# GS4PB Shiny App (AI Version) - Launcher
# Usage: ./ai/run_app_ai.sh [--config path/to/config_ai.env]
#
# Requires:
#   - Apptainer or Singularity
#   - gs4pb_ai.sif  (pulled from umnlorenzgroup/gs4pb:ai-latest)
#   - ai/env/.env   (contains ANTHROPIC_API_KEY=sk-ant-...)
# =============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Parse optional --config flag ---------------------------
CONFIG="${SCRIPT_DIR}/config_ai.env"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--config path/to/config_ai.env]"
      exit 0 ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# --- Load config --------------------------------------------
if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: Config file not found: $CONFIG"
  exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG"

# --- Load .env (Anthropic API key) --------------------------
ENV_FILE="${SCRIPT_DIR}/env/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERROR: API key file not found: $ENV_FILE"
  echo "       Create ai/env/.env with the following content:"
  echo "         ANTHROPIC_API_KEY=sk-ant-..."
  exit 1
fi
# shellcheck source=/dev/null
source "$ENV_FILE"

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "ERROR: ANTHROPIC_API_KEY is not set in $ENV_FILE"
  exit 1
fi

# --- Validate singularity/apptainer is available ------------
if command -v apptainer &>/dev/null; then
  RUNTIME="apptainer"
elif command -v singularity &>/dev/null; then
  RUNTIME="singularity"
else
  echo "ERROR: Neither 'apptainer' nor 'singularity' found in PATH."
  exit 1
fi

# --- Validate .sif image exists -----------------------------
if [[ ! -f "$SIF_IMAGE" ]]; then
  echo "ERROR: Container image not found: $SIF_IMAGE"
  echo "       Pull with:"
  echo "         singularity pull gs4pb_ai.sif docker://umnlorenzgroup/gs4pb:ai-latest"
  exit 1
fi

# --- Create bind-mount directories --------------------------
WORK_DIR="${SCRIPT_DIR}/runtime"
R_HOME="${WORK_DIR}/r-home"
R_TMP="${WORK_DIR}/r-tmp"
RESULTS_DIR="${WORK_DIR}/results"

mkdir -p "$R_HOME" "$R_TMP" "$RESULTS_DIR"
chmod 700 "$R_HOME"
chmod 1777 "$R_TMP"

echo "============================================="
echo "  GS4PB Shiny App (AI Version)"
echo "  Runtime  : $RUNTIME"
echo "  Image    : $SIF_IMAGE"
echo "  App      : $APP"
echo "  URL      : http://localhost:${PORT}"
echo "  API key  : ${ANTHROPIC_API_KEY:0:16}..."
echo "============================================="

# --- Launch -------------------------------------------------
APPTAINERENV_HOME="/r-home" \
APPTAINERENV_TMPDIR="/r-tmp" \
APPTAINERENV_PATH="/usr/local/lib/R/bin:/usr/local/bin:/usr/bin:/bin" \
APPTAINERENV_LD_LIBRARY_PATH="/usr/local/lib/R/lib:/usr/lib/R/lib:/usr/lib/jvm/java-11-openjdk-amd64/lib/server" \
APPTAINERENV_ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
"$RUNTIME" exec \
  --no-home \
  --cleanenv \
  --writable-tmpfs \
  --bind "${R_HOME}:/r-home" \
  --bind "${R_TMP}:/r-tmp" \
  --bind "${RESULTS_DIR}:/root/Results" \
  "$SIF_IMAGE" \
  Rscript --vanilla -e "shiny::runApp('${APP}', port=${PORT}, host='${HOST}')"
