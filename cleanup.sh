#!/bin/bash

echo "Stopping and removing ACE-Step containers..."
docker-compose down

echo "Removing named volumes..."
docker volume prune -f

echo "Removing unused images..."
docker image prune -f

echo "Cleanup complete!"