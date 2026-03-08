#!/bin/bash
# Modified ACE-Step UI Setup Script for Remote Backend

set -e

echo "=================================="
echo "  ACE-Step UI Setup (Remote Backend)"
echo "=================================="

# Create .env file with remote backend configuration
echo "Creating .env file with remote backend configuration..."
cat > .env << EOF
# ACE-Step UI Configuration

# API endpoint for ACE-Step backend
ACESTEP_API_URL=http://ace-step-backend:8001

# Server ports
PORT=3000
FRONTEND_PORT=3000

# Database
DATABASE_PATH=./server/data/acestep.db
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