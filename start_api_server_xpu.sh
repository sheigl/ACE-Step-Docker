#!/bin/bash
# ACE-Step REST API Server Launcher - Intel XPU
# For Intel Arc GPUs (A770, A750, A580, A380) and integrated graphics
# Requires: Python 3.11, PyTorch XPU nightly from download.pytorch.org/whl/xpu
# IMPORTANT: Uses torch.xpu backend with SYCL/Level Zero acceleration

# ==================== XPU Configuration ====================
# XPU performance optimization (from verified working setup)
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
HOST=127.0.0.1
# HOST=0.0.0.0
PORT=8001

# ==================== Model Configuration ====================
# API key for authentication (optional)
# API_KEY=--api-key sk-your-secret-key

# Download source: auto, huggingface, modelscope
DOWNLOAD_SOURCE=

# LLM (Language Model) initialization settings
# By default, LLM is auto-enabled/disabled based on GPU VRAM:
#   - <=6GB VRAM: LLM disabled (DiT-only mode)
#   - >6GB VRAM: LLM enabled
# Values: auto (default), true (force enable), false (force disable)
ACESTEP_INIT_LLM=auto
# ACESTEP_INIT_LLM=true
# ACESTEP_INIT_LLM=false

# LM model path (optional, only used when LLM is enabled)
# Available models: acestep-5Hz-lm-0.6B, acestep-5Hz-lm-1.7B, acestep-5Hz-lm-4B
# LM_MODEL_PATH=--lm-model-path acestep-5Hz-lm-4B

# Update check on startup (set to false to disable)
CHECK_UPDATE=true
# CHECK_UPDATE=false

# Skip model loading at startup (models will be lazy-loaded on first request)
# Set to true to start server quickly without loading models
# ACESTEP_NO_INIT=false
# ACESTEP_NO_INIT=true

# ==================== Venv Configuration ====================
# Path to the XPU virtual environment (relative to this script)
VENV_DIR="$(dirname "$0")/venv_xpu"

# ==================== Launch ====================

# ==================== Startup Update Check ====================
#if [ "${CHECK_UPDATE,,}" != "true" ]; then
#    SKIP_UPDATE_CHECK=1
#fi#
#if [ -z "$SKIP_UPDATE_CHECK" ]; then
#    # Find git: try system git
#    UPDATE_GIT_CMD=""
#    if command -v git &> /dev/null; then
#        UPDATE_GIT_CMD=$(which git)
#    fi
#    
#    if [ -z "$UPDATE_GIT_CMD" ]; then
#        SKIP_UPDATE_CHECK=1
#    else
#        cd "$(dirname "$0")"
#        
#        # Check if in a git repository
#        if ! git rev-parse --git-dir > /dev/null 2>&1; then
#            SKIP_UPDATE_CHECK=1
#        fi
#    fi
#fi#
#if [ -z "$SKIP_UPDATE_CHECK" ]; then
#    echo "[Update] Checking for updates..."
#    
#    UPDATE_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
#    if [ -z "$UPDATE_BRANCH" ]; then
#        UPDATE_BRANCH=main
#    fi
#    
#    UPDATE_LOCAL=$(git rev-parse --short HEAD 2>/dev/null)
#    
#    git fetch origin --quiet 2>/dev/null
#    if [ $? -ne 0 ]; then
#        echo "[Update] Network unreachable, skipping."
#        echo
#        SKIP_UPDATE_CHECK=1
#    fi
#    
#    if [ -z "$SKIP_UPDATE_CHECK" ]; then
#        UPDATE_REMOTE=$(git rev-parse --short origin/"$UPDATE_BRANCH" 2>/dev/null)
#        
#        if [ -z "$UPDATE_REMOTE" ]; then
#            SKIP_UPDATE_CHECK=1
#        elif [ "$UPDATE_LOCAL" = "$UPDATE_REMOTE" ]; then
#            echo "[Update] Already up to date ($UPDATE_LOCAL)."
#            echo
#            SKIP_UPDATE_CHECK=1
#        fi
#    fi
#fi#
#if [ -z "$SKIP_UPDATE_CHECK" ]; then
#    echo
#    echo "========================================"
#    echo "  Update available!"
#    echo "========================================"
#    echo "   Current: $UPDATE_LOCAL  ->  Latest: $UPDATE_REMOTE"
#    echo
#    echo "   Recent changes:"
#    git --no-pager log --oneline HEAD..origin/"$UPDATE_BRANCH" 2>/dev/null
#    echo
#    
#    read -p "Update now before starting? (Y/N): " UPDATE_NOW
#    if [ "${UPDATE_NOW,,}" = "y" ]; then
#        if [ -f "$(dirname "$0")/check_update.sh" ]; then
#            bash "$(dirname "$0")/check_update.sh"
#        else
#            echo "Pulling latest changes..."
#            git pull --ff-only origin "$UPDATE_BRANCH" 2>/dev/null
#            if [ $? -ne 0 ]; then
#                echo "[Update] Update failed. Please update manually."
#            fi
#        fi
#    else
#        echo "[Update] Skipped. Run check_update.sh to update later."
#    fi
#    echo
#fi

echo "============================================"
echo "  ACE-Step 1.5 API - Intel XPU Edition"
echo "============================================"
echo

# Activate venv if it exists
if [ -f "$VENV_DIR/bin/activate" ]; then
    echo "Activating XPU virtual environment: $VENV_DIR"
    source "$VENV_DIR/bin/activate"
else
    echo "========================================"
    echo " ERROR: venv_xpu not found!"
    echo "========================================"
    echo
    echo "Please create the XPU virtual environment first:"
    echo
    echo "  1. Run: python3 -m venv venv_xpu"
    echo "  2. Run: source venv_xpu/bin/activate"
    echo "  3. Run: pip install -r requirements-xpu.txt"
    echo
    echo "Or use the setup script (if available)"
    echo "  ./setup_xpu.sh"
    echo
    read -p "Press [Enter] to continue..."
    exit 1
fi
echo

# Verify XPU PyTorch is installed
python3 -c "import torch; assert hasattr(torch, 'xpu') and torch.xpu.is_available(), 'Intel XPU not detected'; print(f'XPU: Intel Arc GPU detected'); print(f'PyTorch XPU version: {torch.__version__}')" 2>/dev/null
if [ $? -ne 0 ]; then
    echo
    echo "========================================"
    echo " ERROR: Intel XPU PyTorch not detected!"
    echo "========================================"
    echo
    echo "Please install PyTorch with XPU support. See requirements-xpu.txt for instructions."
    echo
    echo "Quick setup:"
    echo "  1. Activate venv: source venv_xpu/bin/activate"
    echo "  2. Install: pip install --upgrade pip"
    echo "  3. Install XPyTorch: pip install -r requirements-xpu.txt"
    echo
    read -p "Press [Enter] to continue..."
    exit 1
fi
echo

echo "Starting ACE-Step REST API Server..."
echo "API will be available at: http://$HOST:$PORT"
echo "API Documentation: http://$HOST:$PORT/docs"
echo

# Build command with optional parameters
CMD_ARGS="--host $HOST --port $PORT"
if [ -n "$API_KEY" ]; then
    CMD_ARGS="$CMD_ARGS $API_KEY"
fi
if [ -n "$DOWNLOAD_SOURCE" ]; then
    CMD_ARGS="$CMD_ARGS $DOWNLOAD_SOURCE"
fi
if [ -n "$LM_MODEL_PATH" ]; then
    CMD_ARGS="$CMD_ARGS $LM_MODEL_PATH"
fi

python3 -u acestep/api_server.py $CMD_ARGS