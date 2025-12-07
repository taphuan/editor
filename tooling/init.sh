set -e

# Default values
SSH_TARGET_IP="${1:-1.1.1.1}"
SSH_TARGET_PORT="${2:-22}"

echo "Applying HAProxy deployment with:"
echo "  SSH_TARGET_IP: ${SSH_TARGET_IP}"
echo "  SSH_TARGET_PORT: ${SSH_TARGET_PORT}"
echo ""

# Export for envsubst
export SSH_TARGET_IP
export SSH_TARGET_PORT

# Check if envsubst is available
if command -v envsubst &> /dev/null; then
    echo "Using envsubst for variable substitution..."
    envsubst < deployment.yaml | kubectl apply -f -
else
    echo "envsubst not found, using sed..."
    sed "s/value: \"1.1.1.1\"/value: \"${SSH_TARGET_IP}\"/g; s/value: \"22\"/value: \"${SSH_TARGET_PORT}\"/g" deployment.yaml | kubectl apply -f -
fi

echo ""
echo "Deployment applied successfully!"
echo "To verify: kubectl get pods -l app=haproxy-ssh-proxy"
