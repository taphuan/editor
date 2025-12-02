#!/bin/bash

# Deployment script for Shared Text Editor

echo "Deploying Shared Text Editor to Kubernetes..."

# Create PVC
echo "Creating PersistentVolumeClaim..."
kubectl apply -f pvc.yaml

# Wait for PVC to be ready
echo "Waiting for PVC to be ready..."
kubectl wait --for=condition=Bound pvc/shared-text-editor-pvc --timeout=60s

# Deploy application
echo "Deploying application..."
kubectl apply -f deployment.yaml

# Create service
echo "Creating service..."
kubectl apply -f service.yaml

# Create ingress (optional)
if [ "$1" == "--with-ingress" ]; then
    echo "Creating ingress..."
    kubectl apply -f ingress.yaml
fi

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl wait --for=condition=available deployment/shared-text-editor --timeout=120s

echo ""
echo "Deployment complete!"
echo ""
echo "To access the application:"
echo "1. Port forward: kubectl port-forward service/shared-text-editor-service 3000:80"
echo "2. Then open: http://localhost:3000"
echo ""
echo "Or if using ingress:"
echo "Update your /etc/hosts file with: <ingress-ip> shared-text-editor.local"
echo "Then open: http://shared-text-editor.local"

