#!/bin/bash
# Setup script for containerized ACE-Step UI that connects to remote backend

set -e

echo "=================================="
echo "  ACE-Step UI Setup (Containerized)"
echo "=================================="

# Create .env file with remote backend configuration
echo "Creating .env file with remote backend configuration..."
cat > .env << EOF
# ACE-Step UI Configuration for Containerized Environment

# API endpoint for ACE-Step backend (this should be the container name in docker-compose)
ACESTEP_API_URL=http://ace-step-backend:8001

# Server ports
PORT=3000
FRONTEND_PORT=3000

# Database
DATABASE_PATH=./server/data/acestep.db

# For containerized environment, we don't need to point to local ACE-Step
# The UI will communicate with the backend API instead
EOF

# Install frontend dependencies
echo ""
echo "Installing frontend dependencies..."
npm install

# Install server dependencies
echo ""
echo "Installing server dependencies..."
cd server
npm install
cd ..

# Initialize database
echo ""
echo "Initializing database..."
cd server
npm run migrate 2>/dev/null || echo "Migration script not found, skipping..."
cd ..

echo ""
echo "=================================="
echo "  Setup Complete!"
echo "=================================="
echo ""
echo "To start the application:"
echo ""
echo "  docker-compose up"
echo ""
echo "Then open http://localhost:3000"
echo ""