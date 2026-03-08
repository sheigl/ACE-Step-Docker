# ACE-Step Docker Setup

This repository provides Docker configurations to containerize both ACE-Step 1.5 and ACE-Step UI applications, enabling them to communicate via Docker containers instead of requiring them to be in the same folder.

## Features

- **Containerized ACE-Step 1.5 API Server** with proper Linux support
- **Containerized ACE-Step UI** with integrated backend
- **Docker Compose** orchestration for easy setup
- **Proper communication** between containers using Docker networking
- **Persistent data storage** for models and user data

## Prerequisites

- Docker and Docker Compose installed
- NVIDIA GPU with CUDA support (for best performance)
- At least 8GB of RAM recommended

## Setup

1. **Clone this repository:**
```bash
git clone https://github.com/your-username/ace-step-docker.git
cd ace-step-docker
```

2. **Make the setup script executable:**
```bash
chmod +x setup.sh
```

3. **Run the setup:**
```bash
./setup.sh
```

## Usage

Once containers are running:
- Access ACE-Step UI at: http://localhost:3000
- Access ACE-Step API documentation at: http://localhost:8001/docs

## Configuration

The setup uses default configurations, but you can customize:
- Ports in `docker-compose.yml`
- Model paths in the volumes section
- Environment variables in the compose file

## Container Communication

The containers communicate via Docker's internal networking:
- `acestep-ui` connects to `acestep-api` using the service name `acestep-api`
- The API URL is set to `http://acestep-api:8001` in the UI container
- This eliminates the need for the UI to depend on the ACE-Step 1.5 project being in the same directory

## Troubleshooting

If you encounter issues:

1. **Check container logs:**
```bash
docker-compose logs acestep-api
docker-compose logs acestep-ui
```

2. **Rebuild containers:**
```bash
docker-compose build --no-cache
docker-compose up -d
```

3. **Ensure proper GPU access:**
For NVIDIA GPUs, make sure you have nvidia-docker2 installed and configured.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐
│   ACE-Step UI   │    │  ACE-Step API   │
│   (Frontend)    │◄──►│   (Backend)     │
│                 │    │                 │
│  Port: 3000     │    │  Port: 8001     │
└─────────────────┘    └─────────────────┘
        ▲                        ▲
        │                        │
        └────────────────────────┘
                Docker Network
```

## License

This project is licensed under the MIT License.