#!/bin/bash

# Load environment variables from .env file
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
else
    echo "Error: .env file not found. Please create it with CLOUDFLARE_ZONE_ID, CLOUDFLARE_API_KEY, and CLOUDFLARE_EMAIL"
    exit 1
fi

# Predefined zone_id from environment
zone_id="$CLOUDFLARE_ZONE_ID"
API_KEY="$CLOUDFLARE_API_KEY"
EMAIL="$CLOUDFLARE_EMAIL"

# Check if the required parameter is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <rule_id>"
  exit 1
fi

rule_id="$1"

# Delete the rule
delete_response=$(curl -s --request DELETE \
  --url "https://api.cloudflare.com/client/v4/zones/$zone_id/email/routing/rules/$rule_id" \
  --header 'Content-Type: application/json' \
  --header "X-Auth-Email: $EMAIL" \
  --header "X-Auth-Key: $API_KEY")

# Check if the deletion was successful
if echo "$delete_response" | grep -q '"success":true'; then
  echo "Success, rule ID \"$rule_id\" deleted!"
else
  echo "Failed to delete rule ID \"$rule_id\"."
fi