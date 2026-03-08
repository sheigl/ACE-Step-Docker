# Use Python 3.11 as base image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ffmpeg \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Install uv package manager
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Set PATH to include uv
ENV PATH="/root/.local/bin:$PATH"

# Copy requirements and install Python dependencies
COPY requirements.txt .
COPY requirements-xpu.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r requirements-xpu.txt

# Copy the rest of the application
COPY . .

# Create necessary directories
RUN mkdir -p /app/checkpoints /app/data /app/public/audio

# Expose the API port
EXPOSE 8001

# Create a non-root user
RUN useradd --create-home --shell /bin/bash appuser
USER appuser
WORKDIR /home/appuser

# Copy application to user directory
COPY --chown=appuser:appuser . /home/appuser/app

# Set working directory to app
WORKDIR /home/appuser/app

# Default command to start the API server
CMD ["uv", "run", "acestep", "--port", "8001", "--enable-api", "--backend", "pt", "--server-name", "0.0.0.0"]