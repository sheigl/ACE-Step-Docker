#!/bin/bash
# Modified Start ACE-Step UI (both frontend and backend) for Containerized Environment

set -e

source $NVM_DIR/nvm.sh

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo "Starting ACE-Step UI with remote backend..."
echo "Backend API URL: $ACESTEP_API_URL"
echo ""

# Wait for backend to be ready
echo "Waiting for backend to be ready..."
until curl -f "$ACESTEP_API_URL/health" 2>/dev/null; do
    echo "Backend not ready, waiting..."
    sleep 5
done

echo "Backend is ready!"

# Start backend in background (if we're running in a container that needs backend)
echo "Starting backend on port ${PORT:-3001}..."
cd server
npm run dev &
BACKEND_PID=$!
cd ..

# Wait for backend
sleep 3

# Start frontend
echo "Starting frontend on port ${FRONTEND_PORT:-3000}..."
npm run dev &

FRONTEND_PID=$!

echo ""
echo "=================================="
echo "  ACE-Step UI Running"
echo "=================================="
echo ""

echo "  Frontend: http://localhost:${FRONTEND_PORT:-3000}"
echo "  Backend:  $ACESTEP_API_URL"
echo ""

echo "Press Ctrl+C to stop..."

# Handle shutdown
trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT TERM

# Wait for processes
wait