FROM node:18-alpine

# Install build dependencies: python3, make, g++, etc. 
RUN apk add --no-cache python3 make g++ bash 
ENV PYTHON=/usr/bin/python3

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json ./

# Install dependencies
RUN npm install --production

# Copy application files
COPY server.js ./
COPY public ./public

# Create data directory
RUN mkdir -p /data

# Expose port
EXPOSE 3000

# Set environment variables
ENV PORT=3000
ENV DATA_FILE=/data/shared-text.txt

# Run the application
CMD ["node", "server.js"]

