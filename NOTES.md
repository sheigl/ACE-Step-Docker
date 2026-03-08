# Notes on ACE-Step Containerization

## Understanding the Architecture

The ace-step-ui repository is designed as a web frontend that communicates with a backend API. Looking at the code structure:

### ace-step-ui (Frontend)
- Written in TypeScript/React
- Makes API calls to a backend service via HTTP requests
- Uses `services/api.ts` to handle all API communication
- The UI itself does NOT run the ace-step processing directly
- The UI has no local ace-step code dependencies - it only calls the API endpoints

### ace-step (Backend) 
- Contains the actual machine learning models and processing code
- Runs on the backend server
- Provides API endpoints for the frontend to call
- Handles GPU acceleration (Intel XPU in our case)

## How This Solution Works

1. **ace-step-ui Container**: 
   - Serves the React frontend
   - Makes API calls to ace-step-backend container
   - Uses `ACESTEP_API_URL` environment variable to know where to send requests
   - No local ace-step or model code needed

2. **ace-step-backend Container**:
   - Runs the actual ace-step processing with Intel XPU support
   - Exposes API endpoints for the UI to communicate with
   - Processes all the ML tasks
   - Uses the XPU for acceleration

## Key Points

- The ace-step-ui DOES NOT run the ace-step backend code directly
- The ace-step-ui simply makes HTTP API calls to the backend
- This is why we can separate them into different containers
- The UI container only needs the frontend code, not the model processing code
- The backend container has all the ace-step and model code

## API Endpoints Used

The UI makes calls to various API endpoints like:
- `/api/songs` - for song management
- `/api/generate` - for generation requests
- `/api/auth` - for authentication
- `/api/training` - for training endpoints

This means that in our container setup:
- The UI container makes requests to `http://ace-step-backend:8001/api/...`
- The backend container handles all those requests and performs the actual processing
- The UI never directly executes ace-step code, it just sends API requests