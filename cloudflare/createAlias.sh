#!/bin/bash

# Load environment variables from .env file
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
else
    echo "Error: .env file not found. Please create it with CLOUDFLARE_ZONE_ID, CLOUDFLARE_API_KEY, and CLOUDFLARE_EMAIL"
    exit 1
fi

# Check if two arguments are passed
if [ "$#" -ne 2 ]; then
  echo "Usage: ./createAlias.sh <source_email> <destination_email>"
  exit 1
fi

# Assign the passed parameters to variables
source_email=$1
destination_email=$2

zone_id="$CLOUDFLARE_ZONE_ID"
API_KEY="$CLOUDFLARE_API_KEY"
EMAIL="$CLOUDFLARE_EMAIL"

curl --request POST \
  --url https://api.cloudflare.com/client/v4/zones/$zone_id/email/routing/rules \
  -H "Content-Type: application/json" \
  -H "X-Auth-Key: $API_KEY" \
  -H "X-Auth-Email: $EMAIL" \
  --data '{
  "actions": [
    {
      "type": "forward",
      "value": [
        "'$destination_email'"
      ]
    }
  ],
  "enabled": true,
  "matchers": [
    {
      "field": "to",
      "type": "literal",
      "value": "'$source_email'"
    }
  ],
  "name": "Send to '$destination_email' rule.",
  "priority": 0
}'