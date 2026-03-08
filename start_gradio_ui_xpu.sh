#!/usr/bin/env bash
# ACE-Step Gradio Web UI Launcher - Intel XPU
# For Intel Arc GPUs (A770, A750, A580, A380) and integrated graphics
# Requires: Python 3.11, PyTorch XPU nightly from download.pytorch.org/whl/xpu
# IMPORTANT: Uses torch.xpu backend with SYCL/Level Zero acceleration

# Get the directory this script lives in
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==================== Helper Functions ====================

load_env_file() {
    local env_file="$SCRIPT_DIR/.env"
    if [[ ! -f "$env_file" ]]; then
        return 0
    fi

    echo "[Config] Loading configuration from .env file..."
    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        [[ -z "$key" || "$key" == \#* ]] && continue
        # Trim leading/trailing whitespace from key
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        case "${key^^}" in
            ACESTEP_CONFIG_PATH)
                [[ -n "$value" ]] && CONFIG_PATH="--config_path $value" ;;
            ACESTEP_LM_MODEL_PATH)
                [[ -n "$value" ]] && LM_MODEL_PATH="--lm_model_path $value" ;;
            ACESTEP_INIT_LLM)
                [[ -n "$value" && "$value" != "auto" ]] && INIT_LLM="--init_llm $value" ;;
            ACESTEP_DOWNLOAD_SOURCE)
                [[ -n "$value" && "$value" != "auto" ]] && DOWNLOAD_SOURCE="--download-source $value" ;;
            ACESTEP_API_KEY)
                [[ -n "$value" ]] && API_KEY="--api-key $value" ;;
            PORT)
                [[ -n "$value" ]] && PORT="$value" ;;
            SERVER_NAME)
                [[ -n "$value" ]] && SERVER_NAME="$value" ;;
            LANGUAGE)
                [[ -n "$value" ]] && LANGUAGE="$value" ;;
            ACESTEP_BATCH_SIZE)
                [[ -n "$value" ]] && BATCH_SIZE="--batch_size $value" ;;
            ACESTEP_OFFLOAD_TO_CPU)
                [[ -n "$value" ]] && OFFLOAD_TO_CPU="--offload_to_cpu $value" ;;
        esac
    done < "$env_file"
    echo "[Config] Configuration loaded from .env"
}

# ==================== Load .env Configuration ====================
load_env_file

# ==================== XPU Configuration ====================
export SYCL_CACHE_PERSISTENT=1
export SYCL_PI_LEVEL_ZERO_USE_IMMEDIATE_COMMANDLISTS=1
export PYTORCH_DEVICE=xpu

# Disable torch.compile (not fully supported on XPU yet)
export TORCH_COMPILE_BACKEND=eager

# HuggingFace tokenizer parallelism
export TOKENIZERS_PARALLELISM=false

# Force torchaudio to use ffmpeg backend (torchcodec not available on XPU)
export TORCHAUDIO_USE_BACKEND=ffmpeg

# ==================== Server Configuration ====================
: "${PORT:=7860}"
: "${SERVER_NAME:=127.0.0.1}"
# SERVER_NAME=0.0.0.0
# SHARE=--share

# UI language: en, zh, ja
: "${LANGUAGE:=en}"

# Batch size: default batch size for generation (1 to GPU-dependent max)
# When not specified, defaults to min(2, GPU_max)
# BATCH_SIZE="--batch_size 4"

# ==================== Model Configuration ====================
: "${CONFIG_PATH:=--config_path acestep-v15-turbo}"
: "${LM_MODEL_PATH:=--lm_model_path acestep-5Hz-lm-4B}"

# CPU offload: recommended for 4B LM on GPUs with <=16GB VRAM
# Models shuttle between CPU/GPU as needed (DiT stays on GPU, LM/VAE/text_encoder move on demand)
# Adds ~8-10s overhead per generation but prevents VRAM oversubscription
# Disable if using 1.7B/0.6B LM or if your GPU has >=20GB VRAM
: "${OFFLOAD_TO_CPU:=--offload_to_cpu true}"

# LLM initialization: auto (default), true, false
# INIT_LLM="--init_llm auto"

# Download source: auto, huggingface, modelscope
: "${DOWNLOAD_SOURCE:=}"

# Auto-initialize models on startup
: "${INIT_SERVICE:=--init_service true}"

# API settings
# ENABLE_API="--enable-api"
# API_KEY="--api-key sk-your-secret-key"

# Authentication
# AUTH_USERNAME="--auth-username admin"
# AUTH_PASSWORD="--auth-password password"

# Update check on startup (set to false to disable)
: "${CHECK_UPDATE:=true}"

# ==================== Venv Configuration ====================
VENV_DIR="$SCRIPT_DIR/venv_xpu"

# ==================== Startup Update Check ====================
if [[ "${CHECK_UPDATE,,}" == "true" ]]; then
    # Find git
    UPDATE_GIT_CMD=""
    if [[ -x "$SCRIPT_DIR/PortableGit/bin/git" ]]; then
        UPDATE_GIT_CMD="$SCRIPT_DIR/PortableGit/bin/git"
    elif command -v git &>/dev/null; then
        UPDATE_GIT_CMD="$(command -v git)"
    fi

    if [[ -n "$UPDATE_GIT_CMD" ]]; then
        cd "$SCRIPT_DIR" || true
        if "$UPDATE_GIT_CMD" rev-parse --git-dir &>/dev/null; then
            echo "[Update] Checking for updates..."

            UPDATE_BRANCH="$("$UPDATE_GIT_CMD" rev-parse --abbrev-ref HEAD 2>/dev/null)"
            [[ -z "$UPDATE_BRANCH" ]] && UPDATE_BRANCH="main"
            UPDATE_LOCAL="$("$UPDATE_GIT_CMD" rev-parse --short HEAD 2>/dev/null)"

            if "$UPDATE_GIT_CMD" fetch origin --quiet 2>/dev/null; then
                UPDATE_REMOTE="$("$UPDATE_GIT_CMD" rev-parse --short "origin/$UPDATE_BRANCH" 2>/dev/null)"

                if [[ -n "$UPDATE_REMOTE" ]]; then
                    if [[ "$UPDATE_LOCAL" == "$UPDATE_REMOTE" ]]; then
                        echo "[Update] Already up to date ($UPDATE_LOCAL)."
                        echo
                    else
                        echo
                        echo "========================================"
                        echo "  Update available!"
                        echo "========================================"
                        echo "  Current: $UPDATE_LOCAL  ->  Latest: $UPDATE_REMOTE"
                        echo
                        echo "  Recent changes:"
                        "$UPDATE_GIT_CMD" --no-pager log --oneline HEAD.."origin/$UPDATE_BRANCH" 2>/dev/null
                        echo

                        read -r -p "Update now before starting? (Y/N): " UPDATE_NOW
                        if [[ "${UPDATE_NOW,,}" == "y" ]]; then
                            if [[ -f "$SCRIPT_DIR/check_update.sh" ]]; then
                                bash "$SCRIPT_DIR/check_update.sh"
                            else
                                echo "Pulling latest changes..."
                                "$UPDATE_GIT_CMD" pull --ff-only "origin" "$UPDATE_BRANCH" 2>/dev/null || \
                                    echo "[Update] Update failed. Please update manually."
                            fi
                        else
                            echo "[Update] Skipped. Run check_update.sh to update later."
                        fi
                        echo
                    fi
                fi
            else
                echo "[Update] Network unreachable, skipping."
                echo
            fi
        fi
    fi
fi

echo "============================================"
echo "  ACE-Step 1.5 - Intel XPU Edition"
echo "============================================"
echo

# Activate venv if it exists
if [[ -f "$VENV_DIR/bin/activate" ]]; then
    echo "Activating XPU virtual environment: $VENV_DIR"
    # shellcheck source=/dev/null
    source "$VENV_DIR/bin/activate"
else
    echo "========================================"
    echo " ERROR: venv_xpu not found!"
    echo "========================================"
    echo
    echo "Please create the XPU virtual environment first:"
    echo
    echo "  1. Run: python -m venv venv_xpu"
    echo "  2. Run: source venv_xpu/bin/activate"
    echo "  3. Run: pip install -r requirements-xpu.txt"
    echo
    echo "Or use the setup script (if available):"
    echo "  bash setup_xpu.sh"
    echo
    exit 1
fi
echo

# Verify XPU PyTorch is installed
if ! python -c "
import torch
assert hasattr(torch, 'xpu') and torch.xpu.is_available(), 'Intel XPU not detected'
print(f'XPU: Intel Arc GPU detected')
print(f'PyTorch XPU version: {torch.__version__}')
" 2>/dev/null; then
    echo
    echo "========================================"
    echo " ERROR: Intel XPU PyTorch not detected!"
    echo "========================================"
    echo
    echo "Please install PyTorch with XPU support. See requirements-xpu.txt for instructions."
    echo
    echo "Quick setup:"
    echo "  1. Activate venv: source venv_xpu/bin/activate"
    echo "  2. Install:       pip install --upgrade pip"
    echo "  3. Install XPU:   pip install -r requirements-xpu.txt"
    echo
    exit 1
fi
echo

echo "Starting ACE-Step Gradio Web UI..."
echo "Server will be available at: http://$SERVER_NAME:$PORT"
echo "Default Model: acestep-v15-turbo"
echo "LM Model: acestep-5Hz-lm-4B (with CPU offload)"
echo
echo "Select your model in the UI if needed!"
echo

# Build command with optional parameters
CMD="--port $PORT --server-name $SERVER_NAME --language $LANGUAGE"
[[ -n "$SHARE"          ]] && CMD="$CMD $SHARE"
[[ -n "$CONFIG_PATH"    ]] && CMD="$CMD $CONFIG_PATH"
[[ -n "$LM_MODEL_PATH"  ]] && CMD="$CMD $LM_MODEL_PATH"
[[ -n "$OFFLOAD_TO_CPU" ]] && CMD="$CMD $OFFLOAD_TO_CPU"
[[ -n "$INIT_LLM"       ]] && CMD="$CMD $INIT_LLM"
[[ -n "$DOWNLOAD_SOURCE" ]] && CMD="$CMD $DOWNLOAD_SOURCE"
[[ -n "$INIT_SERVICE"   ]] && CMD="$CMD $INIT_SERVICE"
[[ -n "$BATCH_SIZE"     ]] && CMD="$CMD $BATCH_SIZE"
[[ -n "$ENABLE_API"     ]] && CMD="$CMD $ENABLE_API"
[[ -n "$API_KEY"        ]] && CMD="$CMD $API_KEY"
[[ -n "$AUTH_USERNAME"  ]] && CMD="$CMD $AUTH_USERNAME"
[[ -n "$AUTH_PASSWORD"  ]] && CMD="$CMD $AUTH_PASSWORD"

# shellcheck disable=SC2086
python -u acestep/acestep_v15_pipeline.py $CMD

read -r -p "Press Enter to exit..."