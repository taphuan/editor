#!/bin/bash

# Set region (or rely on AWS CLI default profile/region)
AWS_REGION="us-east-1"

echo "Listing all Parameter Store parameters and their values in region: $AWS_REGION"

# Get all parameter names
PARAMS=$(aws ssm describe-parameters \
    --region "$AWS_REGION" \
    --query "Parameters[].Name" \
    --output text)

# Loop through each parameter and fetch its value
for PARAM in $PARAMS; do
  VALUE=$(aws ssm get-parameter \
      --name "$PARAM" \
      --region "$AWS_REGION" \
      --with-decryption \
      --query "Parameter.Value" \
      --output text)
  echo "$PARAM = $VALUE"
done
