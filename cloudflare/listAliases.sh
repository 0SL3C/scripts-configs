#!/bin/bash

# Load environment variables from .env file
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
else
    echo "Error: .env file not found. Please create it with CLOUDFLARE_ZONE_ID, CLOUDFLARE_API_KEY, and CLOUDFLARE_EMAIL"
    exit 1
fi

zone_id="$CLOUDFLARE_ZONE_ID"
API_KEY="$CLOUDFLARE_API_KEY"
EMAIL="$CLOUDFLARE_EMAIL"

# Fetch the routing rules
response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/email/routing/rules" \
-H "X-Auth-Email: $EMAIL" \
-H "X-Auth-Key: $API_KEY" \
-H "Content-Type: application/json")

# Check if the request was successful
success=$(echo "$response" | grep -o '"success":true')

if [ -z "$success" ]; then
  echo "Failed to retrieve rules."
  exit 1
fi

# Parse and format the output, storing in a temporary file
temp_file=$(mktemp)

# Extracting id, source, and destination emails
echo "$response" | grep -o '"id":"[^"]*"\|"value":\s*\[\s*"\([^"]*\)"\|"value":\s*"\([^"]*\)"' | \
while read -r line; do
  case $line in
    *\"id\":\"*) 
      id=$(echo "$line" | sed 's/.*"id":"\([^"]*\)".*/\1/')
      ;;
    *\"value\":[*\"*) 
      destination_email=$(echo "$line" | sed 's/.*"value":\s*\[\s*"\([^"]*\)".*/\1/')
      echo "{\"id\":\"$id\",\"source\":\"$source_email\",\"destination\":\"$destination_email\"}" >> "$temp_file"
      source_email="" # Reset source_email for next entry
      ;;
    *\"value\":\"*) 
      source_email=$(echo "$line" | sed 's/.*"value":"\([^"]*\)".*/\1/')
      ;;
  esac
done

# Sort the output alphabetically by destination email
sort -t '"' -k 6 "$temp_file"

# Clean up the temporary file
rm -f "$temp_file"


# curl --request GET \
#   --url https://api.cloudflare.com/client/v4/zones/fd3e4b2afb0d1c90cd5c13d08dc8aa1a/email/routing/rules \
#   --header 'Content-Type: application/json' \
#   --header "X-Auth-Email: $EMAIL" \
#   --header "X-Auth-Key: $API_KEY"
