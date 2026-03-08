# Use Node.js 18 as base image
FROM node:18-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Install dependencies globally
RUN npm install -g pnpm

# Copy package files
COPY package*.json ./

# Install Node.js dependencies
RUN pnpm install

# Copy the rest of the application
COPY . .

# Create necessary directories
RUN mkdir -p /app/data /app/public/audio

# Expose the UI port
EXPOSE 3000

# Create a non-root user
RUN useradd --create-home --shell /bin/bash appuser
USER appuser
WORKDIR /home/appuser

# Copy application to user directory
COPY --chown=appuser:appuser . /home/appuser/app

# Set working directory to app
WORKDIR /home/appuser/app

# Build the application
RUN pnpm build

# Default command to start the UI server
CMD ["pnpm", "start"]