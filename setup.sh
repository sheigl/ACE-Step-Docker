#!/bin/bash

echo "Setting up ACE-Step containers..."

# Create required directories
mkdir -p models data ui-data

# Build and start the containers
echo "Building and starting containers..."
docker-compose up -d

echo "Containers are now running:"
echo "  - ACE-Step API: http://localhost:8001"
echo "  - ACE-Step UI: http://localhost:3000"

echo ""
echo "To view logs:"
echo "  docker-compose logs -f acestep-api"
echo "  docker-compose logs -f acestep-ui"

echo ""
echo "To stop containers:"
echo "  docker-compose down"