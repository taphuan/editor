# gcloud auth login
# gcloud auth list
# 
PROJECT_ID=""
gcloud config set project $GOOGLE_CLOUD_PROJECT

gcloud services enable pubsub.googleapis.com
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
  --member="user:$USER_EMAIL" \
  --role="roles/pubsub.editor"
# Create Topic
gcloud pubsub topics create test
# Create Subscription
gcloud pubsub subscriptions create test-sub --topic=test

# Pull a topic
gcloud pubsub subscriptions pull test-sub --limit=1 --auto-ack --format="value(DATA)" 

# Pull topic, first line of a file as the filename, and then write the remaining lines (from line 2 onward) into that file
readFile(){
    data=$(gcloud pubsub subscriptions pull test-sub --limit=1 --auto-ack --format="value(DATA)")
    filename=$(echo "$data" | head -n1)
    echo "$data" | tail -n +2 > "$filename"
}

# Read a base64 tar file
readTar(){
    file=$(mktemp)
    gcloud pubsub subscriptions pull test-sub --limit=1 --auto-ack --format="value(DATA)" > "$file"
    base64 -d "$file" > $1
    rm "$file"
}
