#!/bin/bash
# Start ACE-Step UI (both frontend and backend)

set -e

source $NVM_DIR/nvm.sh

# Load environment
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

echo "Starting ACE-Step UI..."
echo "ACE-Step: $ACESTEP_PATH"
echo ""

# Start backend in background
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
echo "  Backend:  http://localhost:${PORT:-3001}"
echo ""
echo "Press Ctrl+C to stop..."

# Handle shutdown
trap "kill $BACKEND_PID $FRONTEND_PID 2>/dev/null; exit" INT TERM

# Wait for processes
wait
