#!/bin/bash
# Start script for ACE-Step containerized setup

echo "Starting ACE-Step with Intel XPU support..."
echo ""

# Build and start containers
docker-compose up --build

echo ""
echo "ACE-Step is now running!"
echo "Access the UI at: http://localhost:3000"
echo "Backend API is available at: http://localhost:8001"