# Shared Text Editor

A simple web application that allows multiple users to view and edit a shared text document. The application uses polling (no websockets) to synchronize changes between users.

## Features

- Shared text editing (up to 10MB)
- Auto-refresh every 3 seconds
- Real-time character count and size display
- Modern, responsive UI
- Persistent storage using Kubernetes volumes

## Technology Stack

- **Backend**: Node.js with Express
- **Frontend**: Vanilla HTML/CSS/JavaScript
- **Containerization**: Docker
- **Orchestration**: Kubernetes

## Local Development

### Prerequisites

- Node.js 14+ installed
- Docker installed (for containerization)

### Running Locally

1. Install dependencies:
```bash
npm install
```

2. Run the server:
```bash
npm start
```

3. Open your browser and navigate to `http://localhost:3000`

## Docker Build

Build the Docker image:

```bash
docker build -t editor:latest .
```

Run the container:

```bash
docker run -d -p 3000:3000 -v $(pwd)/data:/data editor:latest
```

## Kubernetes Deployment

### Prerequisites

- Kubernetes cluster running
- kubectl configured to access your cluster

### Deploy to Kubernetes

1. Build and push the Docker image to your registry:
```bash
docker build -t your-registry/editor:latest .
docker push your-registry/editor:latest
```

2. Update the image in `k8s/deployment.yaml` if using a different registry

3. Deploy the application:
```bash
# Create PersistentVolumeClaim
kubectl apply -f k8s/pvc.yaml

# Deploy the application
kubectl apply -f k8s/deployment.yaml

# Create the service
kubectl apply -f k8s/service.yaml

# (Optional) Create ingress if you have an ingress controller
kubectl apply -f k8s/ingress.yaml
```

4. Check the deployment status:
```bash
kubectl get pods
kubectl get services
kubectl get pvc
```

5. Access the application:
   - If using ingress: `http://editor.local` (update hosts file if needed)
   - Port forward: `kubectl port-forward service/editor-service 3000:80`
   - Then access: `http://localhost:3000`

## Configuration

Environment variables:

- `PORT`: Server port (default: 3000)
- `DATA_FILE`: Path to the text file (default: /data/shared-text.txt)

## Notes

- The application stores text in a file on disk
- For Kubernetes deployment, a PersistentVolumeClaim is used to persist data
- The application supports text up to 10MB
- Auto-refresh happens every 3 seconds
- Multiple replicas will share the same PVC, but only one can mount it with ReadWriteOnce access mode

