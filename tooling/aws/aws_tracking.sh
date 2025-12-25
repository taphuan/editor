#!/bin/bash

# Variables
AWS_REGION="us-east-1"          # adjust to your region
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
BUCKET_NAME="cloudtrail-logs-${ACCOUNT_ID}-${AWS_REGION}"
TRAIL_NAME="RealtimeTrail"
LOG_GROUP="/aws/cloudtrail/realtime"

# Step 1: Ensure S3 bucket exists
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "Bucket $BUCKET_NAME does not exist. Creating..."
  aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" 
else
  echo "Bucket $BUCKET_NAME already exists."
fi

# Step 2: Create CloudTrail trail if not exists
TRAIL_EXISTS=$(aws cloudtrail describe-trails --query "trailList[?Name=='$TRAIL_NAME'].Name" --output text)
if [ -z "$TRAIL_EXISTS" ]; then
  echo "Creating CloudTrail trail $TRAIL_NAME..."
  aws s3api put-bucket-policy \
    --bucket "$BUCKET_NAME" \
    --policy file://bucket-policy.json

  aws cloudtrail create-trail \
    --name "$TRAIL_NAME" \
    --s3-bucket-name "$BUCKET_NAME" 
  aws cloudtrail start-logging --name "$TRAIL_NAME"
else
  echo "CloudTrail trail $TRAIL_NAME already exists."
fi

# Step 3: Ensure CloudWatch Logs group exists
if ! aws logs describe-log-groups --query "logGroups[?logGroupName=='$LOG_GROUP'].logGroupName" --output text | grep -q "$LOG_GROUP"; then
  echo "Creating CloudWatch Logs group $LOG_GROUP..."
  aws logs create-log-group --log-group-name "$LOG_GROUP"
else
  echo "CloudWatch Logs group $LOG_GROUP already exists."
fi

# Step 4: Link CloudTrail to CloudWatch Logs (requires IAM role)
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/CloudTrail_CloudWatchRole"
aws cloudtrail update-trail \
  --name "$TRAIL_NAME" \
  --cloud-watch-logs-log-group-arn "arn:aws:logs:${AWS_REGION}:${ACCOUNT_ID}:log-group:$LOG_GROUP" \
  --cloud-watch-logs-role-arn "$ROLE_ARN"

# Step 5: Tail CloudWatch Logs in real time
STREAM_NAME=$(aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP" \
    --query "logStreams[0].logStreamName" \
    --output text)

echo "Monitoring CloudTrail events in real time..."
while true; do
  aws logs get-log-events \
      --log-group-name "$LOG_GROUP" \
      --log-stream-name "$STREAM_NAME" \
      --limit 20 \
      --start-from-head \
      --output json | jq -r '.events[].message'
  sleep 5
done
