# ACE-Step Containerized Setup with Intel XPU Support

This repository contains the necessary files to containerize both the ACE-Step backend and UI components to work together using Intel Arc GPU (XPU).

## Architecture

The setup includes two Docker containers:

1. **ace-step-backend**: The ACE-Step backend with Intel XPU support
2. **ace-step-ui**: The web UI that communicates with the backend via API

## Key Features

- **Intel XPU Support**: Utilizes Intel's XPU (GPU) for accelerated computations
- **Containerized Architecture**: Backend and UI run in separate containers
- **Remote API Communication**: UI communicates with backend via HTTP API
- **GPU Access**: Properly configured for Intel GPU acceleration
- **Health Checks**: Built-in health checks for service monitoring

## Prerequisites

- Docker and Docker Compose installed
- Intel Arc GPU with XPU support
- Docker GPU support enabled (for Intel XPU)

## Setup Instructions

1. **Clone this repository**:
   ```bash
   git clone https://github.com/sheigl/ACE-Step-Docker.git
   cd ACE-Step-Docker
   ```

2. **Build and start the containers**:
   ```bash
   docker-compose up --build
   ```

3. **Access the application**:
   - UI: http://localhost:3000
   - Backend API: http://localhost:8001

## How It Works

The ace-step-ui is designed to make API calls to a backend service. In this containerized setup:

- The UI container makes HTTP requests to `http://ace-step-backend:8001` 
- All processing is handled by the backend container with Intel XPU acceleration
- The UI acts as a frontend interface that communicates with the backend API
- This eliminates the need for the UI to have local ace-step installation

## Configuration

The setup uses environment variables defined in `.env` file:
- `ACESTEP_API_URL`: URL of the backend API (set to `http://ace-step-backend:8001`)
- `PORT`: Port for the UI service
- `DATABASE_PATH`: Path to database file

## Directory Structure

- `Dockerfile.backend`: Dockerfile for the ACE-Step backend
- `Dockerfile.ui`: Dockerfile for the ACE-Step UI  
- `docker-compose.yml`: Docker Compose configuration
- `start_api_server_xpu.sh`: Script to start the backend API server
- `start_gradio_ui_xpu.sh`: Script to start the Gradio UI (not used in containerized version)

## Troubleshooting

If you encounter issues with GPU access:

1. **Verify Docker GPU support**:
   ```bash
   docker info | grep -i gpu
   ```

2. **Ensure Intel GPU drivers are installed**:
   ```bash
   lspci | grep -i vga
   ```

3. **Check if containers can access GPU**:
   ```bash
   docker exec -it ace-step-backend nvidia-smi
   # For Intel XPU, check for SYCL devices
   ```

## License

This project is based on the ACE-Step project and inherits its licensing terms.