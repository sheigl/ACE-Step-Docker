import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { createServer } from 'http';
import { Server } from 'socket.io';
import { setupRoutes } from './routes';
import { setupDatabase } from './db';
import { logger } from './utils/logger';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;
const ACESTEP_API_URL = process.env.ACESTEP_API_URL || 'http://localhost:8001';

// Middleware
app.use(helmet());
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:5173',
  credentials: true
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Setup database
setupDatabase();

// Setup routes
setupRoutes(app, ACESTEP_API_URL);

// Create HTTP server
const server = createServer(app);

// Setup Socket.IO
const io = new Server(server, {
  cors: {
    origin: process.env.FRONTEND_URL || 'http://localhost:5173',
    credentials: true
  }
});

// Handle socket connections
io.on('connection', (socket) => {
  logger.info('Client connected');
  
  socket.on('disconnect', () => {
    logger.info('Client disconnected');
  });
});

// Start server
server.listen(PORT, () => {
  logger.info(`Server is running on port ${PORT}`);
  logger.info(`ACE-Step API URL: ${ACESTEP_API_URL}`);
});

export { app, server, io };