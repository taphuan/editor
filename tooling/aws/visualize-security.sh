# Example usage of the security visualization script

echo "AWS Security Groups and NACLs Visualizer - Example Usage"
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 not found"
    exit 1
fi

# Check if boto3 is installed
if ! python3 -c "import boto3" 2>/dev/null; then
    echo "Installing boto3..."
    pip3 install boto3
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured"
    echo "Please run: aws configure"
    exit 1
fi

echo "✓ Python found"
echo "✓ boto3 installed"
echo "✓ AWS credentials configured"
echo ""

# Get current region
REGION=$(aws configure get region || echo "us-east-1")
echo "Using region: $REGION"
echo ""

# Run the visualization script
echo "Generating security visualization..."
python3 visualize-security.py --region "$REGION" --output security-visualization.md

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Visualization generated successfully!"
    echo ""
    echo "Output file: security-visualization.md"
    echo ""
    echo "To view the diagrams:"
    echo "  1. Open security-visualization.md in VS Code with Mermaid extension"
    echo "  2. Or view on GitHub/GitLab (Mermaid renders automatically)"
    echo "  3. Or use https://mermaid.live/ to view online"
    echo ""
    echo "Other options:"
    echo "  - Generate Mermaid diagrams only:"
    echo "    python3 visualize-security.py --format mermaid"
    echo ""
    echo "  - Analyze specific flow:"
    echo "    python3 visualize-security.py --source-sg sg-xxx --target-sg sg-yyy"
else
    echo "Error generating visualization"
    exit 1
fi

