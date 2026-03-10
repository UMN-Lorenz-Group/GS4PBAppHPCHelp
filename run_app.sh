#!/usr/bin/env bash
# =============================================================
# GS4PB Shiny App - Launcher
# Usage: ./run_app.sh [--config path/to/config.env]
# =============================================================
set -euo pipefail

# --- Resolve script directory so it works from any CWD ------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Parse optional --config flag ---------------------------
CONFIG="${SCRIPT_DIR}/config.env"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config) CONFIG="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: $0 [--config path/to/config.env]"
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
  echo "       Set SIF_IMAGE in config.env or place the .sif file in: $SCRIPT_DIR"
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
echo "  GS4PB Shiny App"
echo "  Runtime  : $RUNTIME"
echo "  Image    : $SIF_IMAGE"
echo "  App      : $APP"
echo "  URL      : http://localhost:${PORT}"
echo "============================================="

# --- Launch -------------------------------------------------
APPTAINERENV_HOME="/r-home" \
APPTAINERENV_TMPDIR="/r-tmp" \
APPTAINERENV_PATH="/usr/local/lib/R/bin:/usr/local/bin:/usr/bin:/bin" \
APPTAINERENV_LD_LIBRARY_PATH="/usr/local/lib/R/lib:/usr/lib/R/lib" \
APPTAINERENV_R_LIBS_USER="$LIB" \
APPTAINERENV_R_LIBS="$LIB" \
"$RUNTIME" exec \
  --no-home \
  --cleanenv \
  --writable-tmpfs \
  --bind "${R_HOME}:/r-home" \
  --bind "${R_TMP}:/r-tmp" \
  --bind "${RESULTS_DIR}:/root/Results" \
  "$SIF_IMAGE" \
  Rscript --vanilla -e "shiny::runApp('${APP}', port=${PORT}, host='${HOST}')"
